#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
#require "#{File.dirname(__FILE__)}/resources/sim"
require "C:/OS-BEopt/OpenStudio-Beopt/resources/sim"

#start the measure
class ProcessConstructionsCrawlspace < OpenStudio::Ruleset::ModelUserScript
  
	class Crawlspace
		def initialize(crawlWallContInsRvalueNominal, crawlCeilingCavityInsRvalueNominal, crawlCeilingJoistHeight, crawlCeilingFramingFactor)
			@crawlWallContInsRvalueNominal = crawlWallContInsRvalueNominal
			@crawlCeilingCavityInsRvalueNominal = crawlCeilingCavityInsRvalueNominal
			@crawlCeilingJoistHeight = crawlCeilingJoistHeight
			@crawlCeilingFramingFactor = crawlCeilingFramingFactor
		end
		
		attr_accessor(:CrawlRimJoistInsRvalue, :ext_perimeter)
		
		def CrawlWallContInsRvalueNominal
			return @crawlWallContInsRvalueNominal
		end
		
		def CrawlCeilingCavityInsRvalueNominal
			return @crawlCeilingCavityInsRvalueNominal
		end
		
		def CrawlCeilingJoistHeight
			return @crawlCeilingJoistHeight
		end
		
		def CrawlCeilingFramingFactor
			return @crawlCeilingFramingFactor
		end
	end
  
	class Carpet
		def initialize(carpetFloorFraction, carpetPadRValue)
			@carpetFloorFraction = carpetFloorFraction
			@carpetPadRValue = carpetPadRValue
		end
		
		attr_accessor(:floor_bare_fraction)
		
		def CarpetFloorFraction
			return @carpetFloorFraction
		end
		
		def CarpetPadRValue
			return @carpetPadRValue
		end
	end
	
	class FloorMass
		def initialize(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
			@floorMassThickness = floorMassThickness
			@floorMassConductivity = floorMassConductivity
			@floorMassDensity = floorMassDensity
			@floorMassSpecificHeat = floorMassSpecificHeat
		end
				
		def FloorMassThickness
			return @floorMassThickness
		end
		
		def FloorMassConductivity
			return @floorMassConductivity
		end
		
		def FloorMassDensity
			return @floorMassDensity
		end
		
		def FloorMassSpecificHeat
			return @floorMassSpecificHeat
		end
	end
	
	class WallSheathing
		def initialize(wallSheathingContInsThickness, wallSheathingContInsRvalue)
			@wallSheathingContInsThickness = wallSheathingContInsThickness
			@wallSheathingContInsRvalue = wallSheathingContInsRvalue
		end
		
		attr_accessor(:rigid_ins_layer_thickness, :rigid_ins_layer_conductivity, :rigid_ins_layer_density, :rigid_ins_layer_spec_heat)
		
		def WallSheathingContInsThickness
			return @wallSheathingContInsThickness
		end
		
		def WallSheathingContInsRvalue
			return @wallSheathingContInsRvalue
		end	
	end
	
	class ExteriorFinish
		def initialize(finishThickness, finishConductivity)
			@finishThickness = finishThickness
			@finishConductivity = finishConductivity
		end
		
		def FinishThickness
			return @finishThickness
		end
		
		def FinishConductivity
			return @finishConductivity
		end
	end	
	
	class CrawlCeilingIns
		def initialize
		end
		attr_accessor(:crawl_ceiling_thickness, :crawl_ceiling_conductivity, :crawl_ceiling_density, :crawl_ceiling_spec_heat, :crawl_ceiling_Rvalue)
	end
	
	class CWallFicR
		def initialize
		end
		attr_accessor(:crawlspace_fictitious_Rvalue)
	end
	
	class CWallIns
		def initialize
		end
		attr_accessor(:crawlspace_wall_thickness, :crawlspace_wall_conductivity, :crawlspace_wall_density, :crawlspace_wall_spec_heat)
	end
	
	class CFloorFicR
		def initialize
		end
		attr_accessor(:crawlspace_floor_Rvalue)
	end
	
	class CSJoistandCavity
		def initialize
		end
		attr_accessor(:crawl_rimjoist_thickness, :crawl_rimjoist_conductivity, :crawl_rimjoist_density, :crawl_rimjoist_spec_heat)
	end
	  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsCrawlspace"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    spacetype_handles = OpenStudio::StringVector.new
    spacetype_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    spacetype_args = model.getSpaceTypes
    spacetype_args_hash = {}
    spacetype_args.each do |spacetype_arg|
      spacetype_args_hash[spacetype_arg.name.to_s] = spacetype_arg
    end

    #looping through sorted hash of model objects
    spacetype_args_hash.sort.map do |key,value|
      spacetype_handles << value.handle.to_s
      spacetype_display_names << key
    end

    #make a choice argument for living
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Of what space type is the living space?")
    args << selected_living

    #make a choice argument for crawlspace
    selected_crawlspace = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcrawlspace", spacetype_handles, spacetype_display_names, true)
    selected_crawlspace.setDisplayName("Of what space type is the crawlspace?")
    args << selected_crawlspace

    #make a choice argument for model objects
    material_handles = OpenStudio::StringVector.new
    material_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    material_args = model.getStandardOpaqueMaterials
    material_args_hash = {}
    material_args.each do |material_arg|
      material_args_hash[material_arg.name.to_s] = material_arg
    end
	
    #looping through sorted hash of model objects
    material_args_hash.sort.map do |key,value|
      material_handles << value.handle.to_s
      material_display_names << key
    end

	#make a choice argument for model objects
	csins_display_names = OpenStudio::StringVector.new
	csins_display_names << "Uninsulated"
	csins_display_names << "Wall"
	csins_display_names << "Ceiling"
	
	#make a choice argument for cs insulation type
	selected_csins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsins", csins_display_names, true)
	selected_csins.setDisplayName("Crawlspace insulation type.")
	args << selected_csins	

	# Wall / Ceiling Insulation
	#make a choice argument for wall / ceiling insulation
	selected_cswallceil = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcswallceil", material_handles, material_display_names, false)
	selected_cswallceil.setDisplayName("Crawlspace wall or ceiling insulation. For manually entering crawlspace wall or ceiling insulation properties, leave blank.")
	args << selected_cswallceil	

	#make a double argument for crawlspace ceiling / wall insulation R-value
	userdefined_cswallceilr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcswallceilr", false)
	userdefined_cswallceilr.setDisplayName("Crawlspace wall continuous insulation or ceiling cavity insulation R-value [hr-ft^2-R/Btu].")
	userdefined_cswallceilr.setDefaultValue(0)
	args << userdefined_cswallceilr
	
	# Ceiling Joist Height
	#make a choice argument for model objects
	joistheight_display_names = OpenStudio::StringVector.new
	joistheight_display_names << "9.25"	
	
	#make a choice argument for crawlspace ceiling joist height
	selected_csceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsceiljoistheight", joistheight_display_names, true)
	selected_csceiljoistheight.setDisplayName("Crawlspace ceiling joist height [in].")
	args << selected_csceiljoistheight	
	
	# Ceiling Framing Factor
	#make a choice argument for model objects
	ceilff_display_names = OpenStudio::StringVector.new
	ceilff_display_names << "0.13"		
	
	#make a choice argument for crawlspace ceiling framing factor
	selected_csceilff = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsceilff", ceilff_display_names, true)
	selected_csceilff.setDisplayName("Crawlspace ceiling framing factor [frac].")
	args << selected_csceilff	
	
	# Rim Joist
	#make a choice argument for rim joist insulation
	selected_csrimjoist = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsrimjoist", material_handles, material_display_names, false)
	selected_csrimjoist.setDisplayName("Crawlspace rim joist insulation. Applies only to crawlspace with wall insulation. For crawlspace with ceiling insulation, rim joist insulation assumes ceiling cavity insulation. For manually entering crawlspace rim joist insulation properties, leave blank.")
	args << selected_csrimjoist		
	
	#make a double argument for rim joist insulation R-value
	userdefined_csrimjoistr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsrimjoistr", false)
	userdefined_csrimjoistr.setDisplayName("Crawlspace rim joist insulation R-value [hr-ft^2-R/Btu].")
	userdefined_csrimjoistr.setDefaultValue(0)
	args << userdefined_csrimjoistr	

	# Floor Mass
	#make a choice argument for floor mass
	selected_floormass = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfloormass", material_handles, material_display_names, false)
	selected_floormass.setDisplayName("Floor mass. For manually entering floor mass properties, leave blank.")
	args << selected_floormass	
	
	#make a double argument for floor mass thickness
	userdefined_floormassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassth", false)
	userdefined_floormassth.setDisplayName("Floor mass thickness [in].")
	userdefined_floormassth.setDefaultValue(0.625)
	args << userdefined_floormassth	
	
	#make a double argument for floor mass conductivity
	userdefined_floormasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasscond", false)
	userdefined_floormasscond.setDisplayName("Floor mass conductivity [Btu-in/h-ft^2-R].")
	userdefined_floormasscond.setDefaultValue(0.8004)
	args << userdefined_floormasscond
	
	#make a double argument for floor mass density
	userdefined_floormassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassdens", false)
	userdefined_floormassdens.setDisplayName("Floor mass density [lb/ft^3].")
	userdefined_floormassdens.setDefaultValue(34.0)
	args << userdefined_floormassdens

	#make a double argument for floor mass specific heat
	userdefined_floormasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasssh", false)
	userdefined_floormasssh.setDisplayName("Floor mass specific heat [Btu/lb-R].")
	userdefined_floormasssh.setDefaultValue(0.29)
	args << userdefined_floormasssh		
	
	# Carpet
	#make a choice argument for carpet pad R-value
	selected_carpet = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcarpet", material_handles, material_display_names, false)
	selected_carpet.setDisplayName("Carpet. For manually entering carpet properties, leave blank.")
	args << selected_carpet
	
	#make a double argument for carpet pad R-value
	userdefined_carpetr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetr", false)
	userdefined_carpetr.setDisplayName("Carpet pad R-value [hr-ft^2-R/Btu].")
	userdefined_carpetr.setDefaultValue(2.08)
	args << userdefined_carpetr
	
	#make a double argument for carpet floor fraction
	userdefined_carpetfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetfrac", false)
	userdefined_carpetfrac.setDisplayName("Carpet floor fraction [frac].")
	userdefined_carpetfrac.setDefaultValue(0.8)
	args << userdefined_carpetfrac	
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	crawlWallContInsRvalueNominal = 0
	crawlCeilingCavityInsRvalueNominal = 0
	crawlRimJoistInsRvalue = 0
	carpetPadRValue = 0

  # Space Type
  selected_crawlspace = runner.getOptionalWorkspaceObjectChoiceValue("selectedcrawlspace",user_arguments,model)
  selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

	# Crawlspace Insulation
	selected_csins = runner.getStringArgumentValue("selectedcsins",user_arguments)
	
	# Wall / Ceiling Insulation
	if ["Wall", "Ceiling"].include? selected_csins.to_s
		selected_cswallceil = runner.getOptionalWorkspaceObjectChoiceValue("selectedcswallceil",user_arguments,model)
		if selected_cswallceil.empty?
			userdefined_cswallceilr = runner.getDoubleArgumentValue("userdefinedcswallceilr",user_arguments)
		end
	end
	
	# Ceiling Joist Height
	selected_csceiljoistheight = runner.getStringArgumentValue("selectedcsceiljoistheight",user_arguments)
	
	# Ceiling Framing Factor
	selected_csceilff = runner.getStringArgumentValue("selectedcsceilff",user_arguments)
	
	# Rim Joist
	if ["Wall"].include? selected_csins.to_s
		selected_csrimjoist = runner.getOptionalWorkspaceObjectChoiceValue("selectedcsrimjoist",user_arguments,model)
		if selected_csrimjoist.empty?
			userdefined_csrimjoistr = runner.getDoubleArgumentValue("userdefinedcsrimjoistr",user_arguments)
		end
	end
	
	# Floor Mass
	selected_slabfloormass = runner.getOptionalWorkspaceObjectChoiceValue("selectedfloormass",user_arguments,model)
	if selected_slabfloormass.empty?
		userdefined_floormassth = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
		userdefined_floormasscond = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
		userdefined_floormassdens = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
		userdefined_floormasssh = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)
	end	
	
	# Carpet
	selected_carpet = runner.getOptionalWorkspaceObjectChoiceValue("selectedcarpet",user_arguments,model)
	if selected_carpet.empty?
		userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
	end
	userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)
	
	# Constants
	mat_wood = get_mat_wood
	mat_soil = get_mat_soil
	mat_concrete = get_mat_concrete
	
	# Insulation
	if selected_csins.to_s == "Wall"
		if userdefined_cswallceilr.nil?
			csWallThickness = OpenStudio::convert(selected_cswallceil.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			csWallConductivity = OpenStudio::convert(selected_cswallceil.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
			crawlWallContInsRvalueNominal = OpenStudio::convert(csWallThickness,"in","ft").get / csWallConductivity	
		else
			crawlWallContInsRvalueNominal = userdefined_cswallceilr
		end
	elsif selected_csins.to_s == "Ceiling"
		if userdefined_cswallceilr.nil?
			csCeilingThickness = OpenStudio::convert(selected_cswallceil.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			csCeilingConductivity = OpenStudio::convert(selected_cswallceil.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get		
			crawlCeilingCavityInsRvalueNominal = OpenStudio::convert(csCeilingThickness,"in","ft").get / csCeilingConductivity
		else
			crawlCeilingCavityInsRvalueNominal = userdefined_cswallceilr
		end
	end
	
	# Ceiling Joist Height
	csCeilingJoistHeight_dict = {"9.25"=>9.25}
	crawlCeilingJoistHeight = csCeilingJoistHeight_dict[selected_csceiljoistheight]	
		
	# Ceiling Framing Factor
	csCeilingFramingFactor_dict = {"0.13"=>0.13}
	crawlCeilingFramingFactor = csCeilingFramingFactor_dict[selected_csceilff]
	
	# Rim Joist
	if ["Wall"].include? selected_csins.to_s
		if userdefined_csrimjoistr.nil?
			csRimJoistThickness = OpenStudio::convert(selected_csrimjoist.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			csRimJoistConductivity = OpenStudio::convert(selected_csrimjoist.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get		
			crawlRimJoistInsRvalue = OpenStudio::convert(csRimJoistThickness,"in","ft").get / csRimJoistConductivity	
		else
			crawlRimJoistInsRvalue = userdefined_csrimjoistr
		end
	end
	
	# Floor Mass
	if userdefined_floormassth.nil?
		floorMassThickness = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
		floorMassConductivity = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
		floorMassDensity = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
		floorMassSpecificHeat = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
	else
		floorMassThickness = userdefined_floormassth
		floorMassConductivity = userdefined_floormasscond
		floorMassDensity = userdefined_floormassdens
		floorMassSpecificHeat = userdefined_floormasssh
	end
	
	# Carpet
	if userdefined_carpetr.nil?
		carpetPadThickness = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
		carpetPadConductivity = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
		carpetPadRValue = OpenStudio::convert(carpetPadThickness,"in","ft").get / carpetPadConductivity
	else
		carpetPadRValue = userdefined_carpetr
	end
	carpetFloorFraction = userdefined_carpetfrac	
	
	# TODO: Some of these options like exterior_finish are shared with exterior walls; how do you avoid entering potentially conflicting input?
	
	# Create the material class instances
	cs = Crawlspace.new(crawlWallContInsRvalueNominal, crawlCeilingCavityInsRvalueNominal, crawlCeilingJoistHeight, crawlCeilingFramingFactor)
	carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)
	floor_mass = FloorMass.new(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
	cci = CrawlCeilingIns.new
	cwfr = CWallFicR.new
	cwi = CWallIns.new
	cffr = CFloorFicR.new
	cjc = CSJoistandCavity.new
	
	if crawlWallContInsRvalueNominal > 0
		cs.CrawlRimJoistInsRvalue = crawlRimJoistInsRvalue
	end
	
	# temp code until figuring out the following TODO:
	# TODO: Some of these options like exterior_finish are shared with exterior walls; how do you avoid entering potentially conflicting input?
	wallSheathingContInsThickness = 0
	wallSheathingContInsRvalue = 0
	finishThickness = 0.375
	finishConductivity = 0.62
	finishDensity = 11.1
	finishSpecHeat = 0.25
	finishThermalAbs = 0.9
	finishSolarAbs = 0.3
	finishVisibleAbs = 0.3
	wallsh = WallSheathing.new(wallSheathingContInsThickness, wallSheathingContInsRvalue)
	exterior_finish = ExteriorFinish.new(finishThickness, finishConductivity)
	
	# Create the sim object
	sim = Sim.new(model)
	
	# Process the crawlspace
	cci, cwfr, cwi, cffr, cjc, wallsh = sim._processConstructionsCrawlspace(cs, carpet, floor_mass, wallsh, exterior_finish, cci, cwfr, cwi, cffr, cjc, selected_crawlspace)
	
	# CrawlCeilingIns
	cciThickness = cci.crawl_ceiling_thickness
	cciConductivity = cci.crawl_ceiling_conductivity
	cciDensity = cci.crawl_ceiling_density
	cciSpecificHeat = cci.crawl_ceiling_spec_heat
	cciRvalue = cci.crawl_ceiling_Rvalue
	if cciRvalue > 0
		cci = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		cci.setName("CrawlCeilingIns")
		cci.setRoughness("Rough")
		cci.setThickness(OpenStudio::convert(cciThickness,"ft","m").get)
		cci.setConductivity(OpenStudio::convert(cciConductivity,"Btu/hr*ft*R","W/m*K").get)
		cci.setDensity(OpenStudio::convert(cciDensity,"lb/ft^3","kg/m^3").get)
		cci.setSpecificHeat(OpenStudio::convert(cciSpecificHeat,"Btu/lb*R","J/kg*K").get)
	end
	
	# Plywood-3_4in
	ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply3_4.setName("Plywood-3_4in")
	ply3_4.setRoughness("Rough")
	ply3_4.setThickness(OpenStudio::convert(get_mat_plywood3_4in(mat_wood).thick,"in","m").get)
	ply3_4.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
	ply3_4.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
	ply3_4.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)
	
	# Plywood-3_2in
	ply3_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply3_2.setName("Plywood-3_2in")
	ply3_2.setRoughness("Rough")
	ply3_2.setThickness(OpenStudio::convert(get_mat_plywood3_2in(mat_wood).thick,"ft","m").get)
	ply3_2.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
	ply3_2.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
	ply3_2.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)	
	
	# FloorMass
	fm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	fm.setName("FloorMass")
	fm.setRoughness("Rough")
	fm.setThickness(OpenStudio::convert(get_mat_floor_mass(floor_mass).thick,"ft","m").get)
	fm.setConductivity(OpenStudio::convert(get_mat_floor_mass(floor_mass).k,"Btu/hr*ft*R","W/m*K").get)
	fm.setDensity(OpenStudio::convert(get_mat_floor_mass(floor_mass).rho,"lb/ft^3","kg/m^3").get)
	fm.setSpecificHeat(OpenStudio::convert(get_mat_floor_mass(floor_mass).Cp,"Btu/lb*R","J/kg*K").get)
	fm.setThermalAbsorptance(get_mat_floor_mass(floor_mass).TAbs)
	fm.setSolarAbsorptance(get_mat_floor_mass(floor_mass).SAbs)
		
	# CWall-FicR
	cwfrRvalue = cwfr.crawlspace_fictitious_Rvalue
	if cwfrRvalue > 0
		cwfr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
		cwfr.setName("CWall-FicR")
		cwfr.setRoughness("Rough")
		cwfr.setThermalResistance(OpenStudio::convert(cwfrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
	end
	
	# Soil-12in
	soil = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	soil.setName("Soil-12in")
	soil.setRoughness("Rough")
	soil.setThickness(OpenStudio::convert(get_mat_soil12in(mat_soil).thick,"ft","m").get)
	soil.setConductivity(OpenStudio::convert(mat_soil.k,"Btu/hr*ft*R","W/m*K").get)
	soil.setDensity(OpenStudio::convert(mat_soil.rho,"lb/ft^3","kg/m^3").get)
	soil.setSpecificHeat(OpenStudio::convert(mat_soil.Cp,"Btu/lb*R","J/kg*K").get)
	
	# Concrete-8in
	conc8 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	conc8.setName("Concrete-8in")
	conc8.setRoughness("Rough")
	conc8.setThickness(OpenStudio::convert(get_mat_concrete8in(mat_concrete).thick,"ft","m").get)
	conc8.setConductivity(OpenStudio::convert(mat_concrete.k,"Btu/hr*ft*R","W/m*K").get)
	conc8.setDensity(OpenStudio::convert(mat_concrete.rho,"lb/ft^3","kg/m^3").get)
	conc8.setSpecificHeat(OpenStudio::convert(mat_concrete.Cp,"Btu/lb*R","J/kg*K").get)
	conc8.setThermalAbsorptance(get_mat_concrete8in(mat_concrete).TAbs)
	
	# CWallIns
	cwiThickness = cwi.crawlspace_wall_thickness
	cwiConductivity = cwi.crawlspace_wall_conductivity
	cwiDensity = cwi.crawlspace_wall_density
	cwiSpecificHeat = cwi.crawlspace_wall_spec_heat
	if cs.CrawlWallContInsRvalueNominal > 0
		cwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		cwi.setName("CWallIns")
		cwi.setRoughness("Rough")
		cwi.setThickness(OpenStudio::convert(cwiThickness,"ft","m").get)
		cwi.setConductivity(OpenStudio::convert(cwiConductivity,"Btu/hr*ft*R","W/m*K").get)
		cwi.setDensity(OpenStudio::convert(cwiDensity,"lb/ft^3","kg/m^3").get)
		cwi.setSpecificHeat(OpenStudio::convert(cwiSpecificHeat,"Btu/lb*R","J/kg*K").get)
	end
	
	# CFloor-FicR
	cffrRvalue = cffr.crawlspace_floor_Rvalue
	cffr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
	cffr.setName("CFloor-FicR")
	cffr.setRoughness("Rough")
	cffr.setThermalResistance(OpenStudio::convert(cffrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
	
	# CSJoistandCavity
	cjcThickness = cjc.crawl_rimjoist_thickness
	cjcConductivity = cjc.crawl_rimjoist_conductivity
	cjcDensity = cjc.crawl_rimjoist_density
	cjcSpecificHeat = cjc.crawl_rimjoist_spec_heat
	cjc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	cjc.setName("CSJoistandCavity")
	cjc.setRoughness("Rough")
	cjc.setThickness(OpenStudio::convert(cjcThickness,"ft","m").get)
	cjc.setConductivity(OpenStudio::convert(cjcConductivity,"Btu/hr*ft*R","W/m*K").get)
	cjc.setDensity(OpenStudio::convert(cjcDensity,"lb/ft^3","kg/m^3").get)
	cjc.setSpecificHeat(OpenStudio::convert(cjcSpecificHeat,"Btu/lb*R","J/kg*K").get)
	
	# Exterior Finish
	extfin = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	extfin.setName("ExteriorFinish")
	extfin.setRoughness("Rough")
	extfin.setThickness(OpenStudio::convert(finishThickness,"in","m").get)
	extfin.setConductivity(OpenStudio::convert(finishConductivity,"Btu*in/hr*ft^2*R","W/m*K").get)
	extfin.setDensity(OpenStudio::convert(finishDensity,"lb/ft^3","kg/m^3").get)
	extfin.setSpecificHeat(OpenStudio::convert(finishSpecHeat,"Btu/lb*R","J/kg*K").get)
	extfin.setThermalAbsorptance(finishThermalAbs)
	extfin.setSolarAbsorptance(finishSolarAbs)
	extfin.setVisibleAbsorptance(finishVisibleAbs)
	
	# Rigid
	if wallSheathingContInsRvalue > 0
		rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		rigid.setName("WallRigidIns")
		rigid.setRoughness("Rough")
		rigid.setThickness(OpenStudio::convert(wallsh.rigid_ins_layer_thickness,"ft","m").get)
		rigid.setConductivity(OpenStudio::convert(wallsh.rigid_ins_layer_conductivity,"Btu/hr*ft*R","W/m*K").get)
		rigid.setDensity(OpenStudio::convert(wallsh.rigid_ins_layer_density,"lb/ft^3","kg/m^3").get)
		rigid.setSpecificHeat(OpenStudio::convert(wallsh.rigid_ins_layer_spec_heat,"Btu/lb*R","J/kg*K").get)
	end
	
	# CarpetBareLayer
	if carpet.CarpetFloorFraction > 0
		cbl = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		cbl.setName("CarpetBareLayer")
		cbl.setRoughness("Rough")
		cbl.setThickness(OpenStudio::convert(get_mat_carpet_bare(carpet).thick,"ft","m").get)
		cbl.setConductivity(OpenStudio::convert(get_mat_carpet_bare(carpet).k,"Btu/hr*ft*R","W/m*K").get)
		cbl.setDensity(OpenStudio::convert(get_mat_carpet_bare(carpet).rho,"lb/ft^3","kg/m^3").get)
		cbl.setSpecificHeat(OpenStudio::convert(get_mat_carpet_bare(carpet).Cp,"Btu/lb*R","J/kg*K").get)
		cbl.setThermalAbsorptance(get_mat_carpet_bare(carpet).TAbs)
		cbl.setSolarAbsorptance(get_mat_carpet_bare(carpet).SAbs)
	end
	
	# UnfinCSInsFinFloor
	layercount = 0
	unfincsinsfinfloor = OpenStudio::Model::Construction.new(model)
	unfincsinsfinfloor.setName("UnfinCSInsFinFloor")
    if cciRvalue > 0
		unfincsinsfinfloor.insertLayer(layercount,cci)
		layercount += 1
	end	
	unfincsinsfinfloor.insertLayer(layercount,ply3_4)
	layercount += 1	
	unfincsinsfinfloor.insertLayer(layercount,fm)
	layercount += 1
	if carpet.CarpetFloorFraction > 0
		unfincsinsfinfloor.insertLayer(layercount,cbl)
	end	

	# RevUnfinCSInsFinFloor
	layercount = 0
	revunfincsinsfinfloor = OpenStudio::Model::Construction.new(model)
	revunfincsinsfinfloor.setName("RevUnfinCSInsFinFloor")
  unfincsinsfinfloor.layers.reverse_each do |layer|
    revunfincsinsfinfloor.insertLayer(layercount,layer)
    layercount += 1
  end

	# GrndInsUnfinCSWall
	layercount = 0
	grndinsunfincswall = OpenStudio::Model::Construction.new(model)
	grndinsunfincswall.setName("GrndInsUnfinCSWall")
	if cwfrRvalue > 0
		grndinsunfincswall.insertLayer(layercount,cwfr)
		layercount += 1
	end
	grndinsunfincswall.insertLayer(layercount,soil)
	layercount += 1
	grndinsunfincswall.insertLayer(layercount,conc8)
	layercount += 1
	if cs.CrawlWallContInsRvalueNominal > 0
		grndinsunfincswall.insertLayer(layercount,cwi)
	end
	
	# GrndUninsUnfinCSFloor
	grnduninsunfincsfloor = OpenStudio::Model::Construction.new(model)
	grnduninsunfincsfloor.setName("GrndUninsUnfinCSFloor")
	grnduninsunfincsfloor.insertLayer(0,cffr)
	grnduninsunfincsfloor.insertLayer(1,soil)	
	
	# CSRimJoist
	layercount = 0
	csrimjoist = OpenStudio::Model::Construction.new(model)
	csrimjoist.setName("CSRimJoist")
	csrimjoist.insertLayer(layercount,extfin)
	layercount += 1
	if wallsh.WallSheathingContInsRvalue > 0
		csrimjoist.insertLayer(layercount,rigid)
		layercount += 1
	end
	csrimjoist.insertLayer(layercount,ply3_2)
	layercount += 1
	csrimjoist.insertLayer(layercount,cjc)

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_crawlspace.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grndinsunfincswall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndInsUnfinCSWall"]
          elsif surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Surface"
            surface.resetConstruction
            surface.setConstruction(revunfincsinsfinfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevUnfinCSInsFinFloor"]
          elsif surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grnduninsunfincsfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndUninsUnfinCSFloor"]
          elsif surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(csrimjoist)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"CSRimJoist"]
          end
        end
      elsif selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Surface"
            adjacentSpaces = model.getSpaces
            adjacentSpaces.each do |adjacentSpace|
              if selected_crawlspace.get.handle.to_s == adjacentSpace.spaceType.get.handle.to_s
                adjacentSurfaces = adjacentSpace.surfaces
                adjacentSurfaces.each do |adjacentSurface|
                  if surface.adjacentSurface.get.handle.to_s == adjacentSurface.handle.to_s
                    surface.resetConstruction
                    surface.setConstruction(unfincsinsfinfloor)
                    constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UnfinCSInsFinFloor"]
                  end
                end
              end
            end
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Surface '#{key}', attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}' and with Surface Type '#{value[0]}' and Outside Boundary Condition '#{value[1]}', was assigned Construction '#{value[2]}'")
      end
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsCrawlspace.new.registerWithApplication