#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsCeilingsRoofsFinishedRoof < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Ceilings/Roofs - Finished Roof Construction"
  end
  
  def description
    return "This measure assigns a construction to finished roofs."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of finished constructions for roofs above finished space."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for finished roof insulation R-value
    cavity_r = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cavity_r", true)
    cavity_r.setDisplayName("Cavity Insulation Installed R-value")
	cavity_r.setUnits("hr-ft^2-R/Btu")
	cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly. If batt insulation must be compressed to fit within the cavity (e.g., R19 in a 5.5\" 2x6 cavity), use an R-value that accounts for this effect (see HUD Mobile Home Construction and Safety Standards 3280.509 for reference).")
    cavity_r.setDefaultValue(30.0)
    args << cavity_r
    
    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    
    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
    selected_installgrade.setDisplayName("Cavity Install Grade")
    selected_installgrade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade

    #make a double argument for wall cavity depth
    selected_cavdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("selectedcavitydepth", true)
    selected_cavdepth.setDisplayName("Cavity Depth")
    selected_cavdepth.setUnits("in")
    selected_cavdepth.setDescription("Depth of the roof cavity. 3.5\" for 2x4s, 5.5\" for 2x6s, etc.")
    selected_cavdepth.setDefaultValue("9.25")
    args << selected_cavdepth
    
	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Insulation Fills Cavity")
	selected_insfills.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    selected_insfills.setDefaultValue(false)
	args << selected_insfills
    
    #make a choice argument for finished roof framing factor
    userdefined_frroofff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfrroofff", false)
    userdefined_frroofff.setDisplayName("Framing Factor")
	userdefined_frroofff.setUnits("frac")
	userdefined_frroofff.setDescription("The framing factor of the finished roof.")
    userdefined_frroofff.setDefaultValue(0.07)
    args << userdefined_frroofff
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Roof above finished space
    spaces = []
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            surfaces << surface
            if not spaces.include? space
                spaces << space
            end
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end       
    
    # Get Inputs
    frRoofCavityInsRvalueInstalled = runner.getDoubleArgumentValue("cavity_r",user_arguments)
    frRoofCavityInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    frRoofCavityDepth = runner.getDoubleArgumentValue("selectedcavitydepth",user_arguments)    
    frRoofCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)
    frRoofFramingFactor = runner.getDoubleArgumentValue("userdefinedfrroofff",user_arguments)
    
    # Validate Inputs
    if frRoofCavityInsRvalueInstalled < 0.0
        runner.registerError("Cavity Insulation Installed R-value must be greater than or equal to 0.")
        return false
    end
    if frRoofCavityDepth <= 0.0
        runner.registerError("Cavity Depth must be greater than 0.")
        return false
    end    
    if frRoofFramingFactor < 0.0 or frRoofFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end

    # Process the finished roof
    
    # Define materials
    if frRoofCavityInsRvalueInstalled > 0
        if frRoofCavityInsFillsCavity
            # Insulation
            mat_cavity = Material.new(name=nil, thick_in=frRoofCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=frRoofCavityDepth / frRoofCavityInsRvalueInstalled)
        else
            # Insulation plus air gap when insulation thickness < cavity depth
            mat_cavity = Material.new(name=nil, thick_in=frRoofCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=frRoofCavityDepth / (frRoofCavityInsRvalueInstalled + Gas.AirGapRvalue))
        end
    else
        # Empty cavity
        mat_cavity = Material.AirCavityClosed(frRoofCavityDepth)
    end
    mat_framing = Material.new(name=nil, thick_in=frRoofCavityDepth, mat_base=BaseMaterial.Wood)
    
    # Set paths
    path_fracs = [frRoofFramingFactor, 1 - frRoofFramingFactor]
    
    # Define construction
    roof = Construction.new(path_fracs)
    roof.add_layer(Material.AirFilmRoof(Geometry.calculate_avg_roof_pitch(spaces)), false)
    roof.add_layer(Material.DefaultCeilingMass, false) # thermal mass added in separate measure
    roof.add_layer([mat_framing, mat_cavity], true, "RoofIns")
    roof.add_layer(Material.DefaultRoofSheathing, false) # roof sheathing added in separate measure
    roof.add_layer(Material.DefaultRoofMaterial, false) # roof material added in separate measure
    roof.add_layer(Material.AirFilmOutside, false)
    
    # Create and assign construction to surfaces
    if not roof.create_and_assign_constructions(surfaces, runner, model, name="FinInsExtRoof")
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsCeilingsRoofsFinishedRoof.new.registerWithApplication