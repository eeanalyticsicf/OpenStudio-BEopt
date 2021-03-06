#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsFoundationsFloorsInterzonalFloors < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Interzonal Floor Construction"
  end
  
  def description
    return "This measure assigns a wood stud construction to floors between finished space and unfinished space or floors below cantilevered finished space."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of wood stud constructions for floors 1) between finished and unfinished spaces or 2) between finished spaces and outside. If the floors have an existing construction, the layers (other than floor covering and floor mass) are replaced. This measure is intended to be used in conjunction with Floor Covering and Floor Mass measures."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("Cavity Insulation Nominal R-value")
    userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
    userdefined_instcavr.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
    userdefined_instcavr.setDefaultValue(19.0)
    args << userdefined_instcavr

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    
    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
    selected_installgrade.setDisplayName("Cavity Install Grade")
    selected_installgrade.setDescription("nstallation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade   

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_floorff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloorff", true)
    userdefined_floorff.setDisplayName("Framing Factor")
    userdefined_floorff.setUnits("frac")
    userdefined_floorff.setDescription("The fraction of a floor assembly that is comprised of structural framing.")
    userdefined_floorff.setDefaultValue(0.13)
    args << userdefined_floorff
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            if surface.outsideBoundaryCondition.downcase == "outdoors"
                # Cantilevered floor between above-grade finished space and outside    
                surfaces << surface
            elsif surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                adjacent_space = surface.adjacentSurface.get.space.get
                next if Geometry.space_is_finished(adjacent_space)
                next if Geometry.space_is_below_grade(adjacent_space)
                # Floor between above-grade finished space and above-grade unfinished space
                surfaces << surface
            end
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end        
    
    # Get Inputs
    intFloorCavityInsRvalueNominal = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    intFloorInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    intFloorFramingFactor = runner.getDoubleArgumentValue("userdefinedfloorff",user_arguments)
    
    # Validate Inputs
    if intFloorCavityInsRvalueNominal < 0.0
        runner.registerError("Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if intFloorFramingFactor < 0.0 or intFloorFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    
    # Process the floors
    
    # Define Materials
    if intFloorCavityInsRvalueNominal == 0
        mat_cavity = Material.AirCavityOpen(thick_in=Material.Stud2x6.thick_in)
    else
        mat_cavity = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=Material.Stud2x6.thick_in / intFloorCavityInsRvalueNominal)
    end
    mat_framing = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.Wood)
    mat_gap = Material.AirCavityClosed(Material.Stud2x6.thick_in)
    
    # Set paths
    izfGapFactor = Construction.get_wall_gap_factor(intFloorInstallGrade, intFloorFramingFactor, intFloorCavityInsRvalueNominal)
    path_fracs = [intFloorFramingFactor, 1 - intFloorFramingFactor - izfGapFactor, izfGapFactor]
    
    # Define construction
    izf_const = Construction.new(path_fracs)
    izf_const.add_layer(Material.AirFilmFloorReduced, false)
    izf_const.add_layer([mat_framing, mat_cavity, mat_gap], true, "IntFloorIns")
    izf_const.add_layer(Material.DefaultFloorSheathing, false) # sheathing added in separate measure
    izf_const.add_layer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
    izf_const.add_layer(Material.DefaultFloorCovering, false) # floor covering added in separate measure
    izf_const.add_layer(Material.AirFilmFloorReduced, false)
    
    # Create and assign construction to surfaces
    if not izf_const.create_and_assign_constructions(surfaces, runner, model, name="UnfinInsFinFloor")
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsInterzonalFloors.new.registerWithApplication