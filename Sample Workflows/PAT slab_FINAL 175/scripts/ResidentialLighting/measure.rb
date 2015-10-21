#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ResidentialLighting < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialLighting"
  end
  
  #define the arguments that the user will input
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for ltgs (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified
	chs = OpenStudio::StringVector.new
	chs << "Benchmark" 
	chs << "Simple"
	chs << "Detailed"
	
	selected_ltg = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_ltg", chs, true)
	selected_ltg.setDisplayName("Lighting Energy Consumption Option")
	args << selected_ltg
	
	#make a double argument for user defined ltg options
	ltg_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ltg_E",true)
	ltg_E.setDisplayName("Simple Interior Lighting Annual Energy Consumption (kWh/yr)")
	ltg_E.setDefaultValue(0)
	args << ltg_E
	
	#make a boolean argument for has outside lighting
	outside_ltg = OpenStudio::Ruleset::OSArgument::makeBoolArgument("outside_ltg",true)
	outside_ltg.setDisplayName("Building has exterior lighting")
	outside_ltg.setDefaultValue(true)
	args << outside_ltg
	
	#make a boolean argument for has garage
	garage_ltg = OpenStudio::Ruleset::OSArgument::makeBoolArgument("garage_ltg",true)
	garage_ltg.setDisplayName("Building has a garage?")
	garage_ltg.setDefaultValue(true)
	args << garage_ltg
	
	#make a boolean argument for has finished basement
	fb_ltg = OpenStudio::Ruleset::OSArgument::makeBoolArgument("fb_ltg",true)
	fb_ltg.setDisplayName("Building has a finished basement?")
	fb_ltg.setDefaultValue(true)
	args << fb_ltg
	
	#make a double argument for finished floor area
	cfa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cfa",true)
	cfa.setDisplayName("Conditioned Floor Area (including basement if finished) (ft^2)")
	cfa.setDefaultValue(1800)
	args << cfa
	
	#make a double argument for garage floor area
	gfa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gfa",true)
	gfa.setDisplayName("Garage Floor Area (ft^2)")
	gfa.setDefaultValue(240)
	args << gfa
	
	#make a double argument for basement floor area
	fbfa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fbfa",true)
	fbfa.setDisplayName("Finished Basement Floor Area (ft^2)")
	fbfa.setDefaultValue(900)
	args << fbfa
	
	#make a double argument for hardwired CFL fraction
	hw_cfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_cfl",true)
	hw_cfl.setDisplayName("Hardwired Fraction CFL")
	hw_cfl.setDefaultValue(0)
	args << hw_cfl
	
	#make a double argument for hardwired LED fraction
	hw_led = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_led",true)
	hw_led.setDisplayName("Hardwired Fraction LED")
	hw_led.setDefaultValue(0)
	args << hw_led
	
	#make a double argument for hardwired LFL fraction
	hw_lfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_lfl",true)
	hw_lfl.setDisplayName("Hardwired Fraction LFL")
	hw_lfl.setDefaultValue(0)
	args << hw_lfl
	
	#make a double argument for Plugin CFL fraction
	pg_cfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pg_cfl",true)
	pg_cfl.setDisplayName("Plugin Fraction CFL")
	pg_cfl.setDefaultValue(0)
	args << pg_cfl
	
	#make a double argument for Plugin LED fraction
	pg_led = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pg_led",true)
	pg_led.setDisplayName("Plugin Fraction LED")
	pg_led.setDefaultValue(0)
	args << pg_led
	
	#make a double argument for Plugin LFL fraction
	pg_lfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pg_lfl",true)
	pg_lfl.setDisplayName("Plugin Fraction LFL")
	pg_lfl.setDefaultValue(0)
	args << pg_lfl
	
	#make a double argument for Incandescent Efficacy
	in_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("in_eff",true)
	in_eff.setDisplayName("Incandescent Efficacy (lm/W))")
	in_eff.setDefaultValue(15)
	args << in_eff
	
	#make a double argument for CFL Efficacy
	cfl_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cfl_eff",true)
	cfl_eff.setDisplayName("CFL Efficacy (lm/W))")
	cfl_eff.setDefaultValue(55)
	args << cfl_eff
	
	#make a double argument for LED Efficacy
	led_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("led_eff",true)
	led_eff.setDisplayName("LED Efficacy (lm/W))")
	led_eff.setDefaultValue(50)
	args << led_eff
	
	#make a double argument for LFL Efficacy
	lfl_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("lfl_eff",true)
	lfl_eff.setDisplayName("LFL Efficacy (lm/W))")
	lfl_eff.setDefaultValue(88)
	args << lfl_eff
	
	#make a choice argument for which zone to put the space in
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    #looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key,value|
      #only include if space type is used in the model
      if value.spaces.size > 0
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end
	
	#make a choice argument for space type
    space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_handles, space_type_display_names)
    space_type.setDisplayName("Select the space where the interior lighting is located")
    space_type.setDefaultValue("*None*") #if none is chosen this will error out
    args << space_type
	
	#make a choice argument for space type
    grg_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("grg_space_type", space_type_handles, space_type_display_names, false)
    grg_space_type.setDisplayName("Select the garage space")
    grg_space_type.setDefaultValue("*None*") #if none is chosen this will error out
    args << grg_space_type
	
	#make a choice argument for space type
    fb_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fb_space_type", space_type_handles, space_type_display_names, false)
    fb_space_type.setDisplayName("Select the finished basement space")
    fb_space_type.setDefaultValue("*None*") #if none is chosen this will error out
    args << fb_space_type
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    fb_ltg = runner.getBoolArgumentValue("fb_ltg",user_arguments)
	outside_ltg = runner.getBoolArgumentValue("outside_ltg",user_arguments)
	garage_ltg = runner.getBoolArgumentValue("garage_ltg",user_arguments)
	selected_ltg = runner.getStringArgumentValue("selected_ltg",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
	
	if fb_ltg
		space_type_fb = runner.getStringArgumentValue("fb_space_type",user_arguments)
	else
		space_type_fb = "none"
	end
	if garage_ltg
		space_type_grg = runner.getStringArgumentValue("grg_space_type",user_arguments)
	else
		space_type_grg = "none"
	end
	
    ltg_E = runner.getDoubleArgumentValue("ltg_E",user_arguments)
	hw_cfl = runner.getDoubleArgumentValue("hw_cfl",user_arguments)
	hw_led = runner.getDoubleArgumentValue("hw_led",user_arguments)
	hw_lfl = runner.getDoubleArgumentValue("hw_lfl",user_arguments)
	pg_cfl = runner.getDoubleArgumentValue("pg_cfl",user_arguments)
	pg_led = runner.getDoubleArgumentValue("pg_led",user_arguments)
	pg_lfl = runner.getDoubleArgumentValue("pg_lfl",user_arguments)
	in_eff = runner.getDoubleArgumentValue("in_eff",user_arguments)
	cfl_eff = runner.getDoubleArgumentValue("cfl_eff",user_arguments)
	led_eff = runner.getDoubleArgumentValue("led_eff",user_arguments)
	lfl_eff = runner.getDoubleArgumentValue("lfl_eff",user_arguments)
	cfa = runner.getDoubleArgumentValue("cfa",user_arguments)
	gfa = runner.getDoubleArgumentValue("gfa",user_arguments)
	fbfa = runner.getDoubleArgumentValue("fbfa",user_arguments)
	fb_ltg = runner.getBoolArgumentValue("fb_ltg",user_arguments)
	outside_ltg = runner.getBoolArgumentValue("outside_ltg",user_arguments)
	garage_ltg = runner.getBoolArgumentValue("garage_ltg",user_arguments)
	
	#Error if fb but no area
	if fb_ltg and fbfa <= 0
		runner.registerError("Finished basement is selected but floor area is <= 0. Double check inputs")
	end
	
	#error if garage but no area
	if garage_ltg and gfa <= 0
		runner.registerError("Garage is selected but floor area is <= 0. Double check inputs")
	end
	
	#warning if things are specified that will not be used (ie. BAB mult when detailed lighting is modeled)
	#Benchmark and other values specified
	if selected_ltg == "Benchmark" and ltg_E != 0
		runner.registerWarning("Benchmark is specified with a non-zero lighting energy. This value will not be used")
	end
	
	#Simple but detailed options specified
	
	if selected_ltg == "Simple" or selected_ltg == "Benchmark"
		if hw_cfl != 0
			runner.registerWarning("Fraction of hardwired CFLs is selected without the detailed calculation method. This value will not be used")
		elsif hw_led != 0
			runner.registerWarning("Fraction of hardwired LEDs is selected without the detailed calculation method. This value will not be used")
		elsif hw_lfl != 0
			runner.registerWarning("Fraction of hardwired LFLs is selected without the detailed calculation method. This value will not be used")
		elsif pg_cfl != 0
			runner.registerWarning("Fraction of plugin CFLs is selected without the detailed calculation method. This value will not be used")
		elsif pg_led != 0
			runner.registerWarning("Fraction of plugin LEDs is selected without the detailed calculation method. This value will not be used")
		elsif pg_lfl != 0
			runner.registerWarning("Fraction of plugin LFLs is selected without the detailed calculation method. This value will not be used")
		elsif in_eff != 15
			runner.registerWarning("Incandescent efficacy is selected without the detailed calculation method. This value will not be used")
		elsif cfl_eff != 55
			runner.registerWarning("CFL efficacy is selected without the detailed calculation method. This value will not be used")
		elsif led_eff != 50
			runner.registerWarning("LED efficacy is selected without the detailed calculation method. This value will not be used")
		elsif lfl_eff != 88
			runner.registerWarning("LFK efficacy is selected without the detailed calculation method. This value will not be used")
		end
		
	end
	
	#Check that the CFA > 0
	if cfa < 0
		runner.registerError("Conditioned floor area must be > 0")
	end
	
	#if lighting energy consumption is defined, check for reasonable energy consumption
	if selected_ltg == "Simple" 
		if ltg_E < 0
			runner.registerError("Electric lighting energy consumption must be greater than 0")
		elsif ltg_E > 10000
			runner.registerError("Electric lighting energy consumption seems high, double check inputs") 
		end
	end
	
	#Calculate electric lighting daily energy use
	lightval = Process_lighting.new
	
	bab_er_cfl = lightval.Bab_er_cfl
	bab_er_led = lightval.Bab_er_led
	bab_er_lfl = lightval.Bab_er_lfl
	bab_frac_inc = lightval.Bab_frac_inc
	bab_frac_cfl = lightval.Bab_frac_cfl
	bab_frac_led = lightval.Bab_frac_led
	bab_frac_lfl = lightval.Bab_frac_lfl
	
	frac_hw = 0.8
    frac_pg = 0.2

    bab_frac_inc = 0.66
    bab_frac_cfl = 0.21
    bab_frac_led = 0.00
    bab_frac_lfl = 0.13

	
	if selected_ltg == "Simple"
		ltg_ann = ltg_E
	end
	if selected_ltg == "Benchmark"
		hw_cfl = 0.21
		hw_led = 0.00
		hw_lfl = 0.13
		pg_cfl = 0.21
		pg_led = 0.00
		pg_lfl = 0.13
		in_eff = 15.0
		cfl_eff = 55.0
		led_eff = 50.0
		lfl_eff = 88.0
	end
		
	hw_inc = 1 - hw_cfl - hw_led - hw_lfl
	pg_inc = 1 - pg_cfl - pg_led - pg_lfl
	bm_hw_e = frac_hw * (cfa * 0.542 + 334)
	bm_pg_e = frac_pg * (cfa * 0.542 + 334)
	smrt_replce_f = (1.29 * hw_inc ** 4 - 2.23 * hw_inc ** 3 + 1.76 * hw_inc ** 2 - 0.82 * hw_inc + 1.170886)
	er_cfl = in_eff / cfl_eff
	er_led = in_eff / led_eff
	er_lfl = in_eff / lfl_eff
	int_hw_e = (bm_hw_e * (((hw_inc + (1 - bab_frac_inc)) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
	int_pg_e = (bm_pg_e * (((pg_inc + (1 - bab_frac_inc)) + (pg_cfl* er_cfl - bab_frac_cfl * bab_er_cfl) + (pg_led * er_led - bab_frac_led * bab_er_led) + (pg_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
	if selected_ltg != "Simple"
		ltg_ann = int_hw_e + int_pg_e
	end
	if garage_ltg
		bm_garage_e =  0.08 * gfa + 8
		garage_ann = (bm_garage_e * (((hw_inc + (1 - bab_frac_inc)) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
		garage_daily = garage_ann / 365.0
	else
		garage_ann = 0.0 
		garage_daily = 0.0
	end
		
	if outside_ltg
		bm_outside_e = 0.145 * cfa
		outside_ann = (bm_outside_e * (((hw_inc + (1 - bab_frac_inc)) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
		outside_daily = outside_ann / 365.0
	else
		outside_ann = 0.0 
		outside_daily = 0.0
	end

	ltg_daily = ltg_ann / 365.0
	
	ltg_total = ltg_ann + garage_ann + outside_ann
	
	#add ltg schedule
	#Calculate the lighting schedule
	site = model.getSite
	weather = site.weatherFile.get
	#epw_file = OpenStudio::EpwFile.new(weather_file)
	
	lat = site.latitude
	long = site.longitude
	tz = site.timeZone
	std_long = -tz*15
	pi = Math::PI
	
	#sunrise and sunset hours
	sunrise_hour = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
	sunset_hour = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
	normalized_hourly_lighting = [[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24]]
	for month in 0..11
		if lat < 51.49
			m_num = month+1
			jul_day = m_num*30-15
			if not (m_num < 4 or m_num > 10)
				offset = 1
			else
				offset = 0
			end
			declination = 23.45 * Math.sin(0.9863 * (284 + jul_day) * 0.01745329)
			deg_rad = pi/180
			rad_deg = 1/deg_rad
			b = (jul_day-1) * 0.9863
			equation_of_time = (0.01667 * (0.01719 + 0.42815 * Math.cos(deg_rad*b) - 7.35205 * Math.sin(deg_rad*b) - 3.34976 * Math.cos(deg_rad*(2*b)) - 9.37199 * Math.sin(deg_rad*(2*b))))
			sunset_hour_angle = rad_deg * (Math.acos(-1 * Math.tan(deg_rad*lat) * Math.tan(deg_rad*declination)))
			sunrise_hour[month] =  offset + (12.0 - 1 * sunset_hour_angle/15.0) - equation_of_time - (std_long + long)/15
			sunset_hour[month] = offset + (12.0 + 1 * sunset_hour_angle/15.0) - equation_of_time - (std_long + long)/15
		else
			sunrise_hour = [8.125726064, 7.449258072, 6.388688653, 6.232405257, 5.27722936, 4.84705384, 5.127512162, 5.860163988, 6.684378904, 7.521267411, 7.390441945, 8.080667697]
			sunset_hour = [16.22214058, 17.08642353, 17.98324493, 19.83547864, 20.65149672, 21.20662992, 21.12124777, 20.37458274, 19.25834757, 18.08155615, 16.14359164, 15.75571306]
		end
	end
				
	dec_kws = lightval.Dec_kws
	june_kws = lightval.June_kws
						
	amplConst1 = lightval.AmplConst1
	sunsetLag1 = lightval.SunsetLag1
	stdDevCons1 = lightval.StdDevCons1
	amplConst2 = lightval.AmplConst2
	sunsetLag2 = lightval.SunsetLag2
	stdDevCons2 = lightval.StdDevCons2
	monthly_kwh_per_day = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
	days_m = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	wtd_avg_monthly_kwh_per_day = 0
	for m in 1..12
		month = m-1
		monthNum = m
		monthHalfHourKWHs = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
		# Calculate hour 12.5 first; others depend on it
		monthHalfHourKWHs[24] = june_kws[24] + ((dec_kws[24] - june_kws[24]) / 2.0 / 0.266 * (1.0 / 1.5 / ((2.0*pi)**0.5)) * Math.exp(-0.5 * (((6 - monthNum).abs - 6) / 1.5)**2)) + ((dec_kws[24] - june_kws[24]) / 2 / 0.399 * (1 / 1 / ((2 * pi)**0.5)) * Math.exp(-0.5 * (((4.847 - sunrise_hour[month]).abs - 3.2) / 1.0)**2))
		for hourNum in 0..10
			monthHalfHourKWHs[hourNum] = june_kws[hourNum]
		end
		for hourNum in 11..16
			hour = (hourNum + 1.0) * 0.5
			monthHalfHourKWHs[hourNum] = june_kws[11] + 0.005 * (sunrise_hour[month] - 3.0)**2.4 * Math.exp(-1.0 * ((hour - 8.0)**2) / (2.0 * 0.8**2)) / (0.8 * (2.0 * pi)**0.5)
		end
		for hourNum in 16..24
			hour = (hourNum + 1.0) * 0.5
			monthHalfHourKWHs[hourNum] = monthHalfHourKWHs[24] + 0.005 * (sunrise_hour[month] - 3.0)**2.4 * Math.exp(-1.0 * ((hour - 8.0)**2) / (2.0 * 0.8**2.0)) / (0.8 * (2.0 * pi)**0.5)
		end
		for hourNum in 25..38
			hour = (hourNum + 1.0) * 0.5
			monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[24] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0*pi)**0.5))
		end
		for hourNum in 38..44
			hour = (hourNum + 1.0) * 0.5
			temp1 = (monthHalfHourKWHs[24] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0*pi)**0.5))
			temp2 = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - (sunsetLag2))**2) / (2.0 * (stdDevCons2)**2)) / (stdDevCons2 * (2.0*pi)**0.5))
			if sunsetLag2 < sunset_hour[month] + sunsetLag1
				monthHalfHourKWHs[hourNum] = [temp1, temp2].min
			else
				monthHalfHourKWHs[hourNum] = [temp1, temp2].max
			end
		end
		for hourNum in 44..48
			hour = (hourNum + 1) * 0.5
			monthHalfHourKWHs[hourNum] = (0.04 + amplConst2 * Math.exp((-1 * (hour - (sunsetLag2))**2) / (2 * (stdDevCons2)**2)) / (stdDevCons2 * (2*pi)**0.5))
		end
		sum_kWh = 0.0
		for timenum in 0..47
			sum_kWh = sum_kWh + monthHalfHourKWHs[timenum]
		end
		for hour in 0..23
			ltg_hour = (monthHalfHourKWHs[hour*2] + monthHalfHourKWHs[hour*2+1]).to_f
			normalized_hourly_lighting[month][hour] = ltg_hour/sum_kWh
			monthly_kwh_per_day[month] = sum_kWh/2.0 
	   end
	   
	   wtd_avg_monthly_kwh_per_day = wtd_avg_monthly_kwh_per_day + monthly_kwh_per_day[month] * days_m[month]/365.0
	end
	
	# Calculate normalized monthly lighting fractions
	seasonal_multiplier = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
	sumproduct_seasonal_multiplier = 0
	normalized_monthly_lighting = seasonal_multiplier
	for month in 0..11
		seasonal_multiplier[month] = (monthly_kwh_per_day[month]/wtd_avg_monthly_kwh_per_day)
		sumproduct_seasonal_multiplier += seasonal_multiplier[month] * days_m[month]
	end
	
	for month in 0..11
		normalized_monthly_lighting[month] = seasonal_multiplier[month] * days_m[month] / sumproduct_seasonal_multiplier
	end
	
	#Calc maxval and schedule values
	lighting_sch = [[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24]]
	ltg_max = 0.0
	for month in 0..11
		for hour in 0..23
			lighting_sch[month][hour] = normalized_monthly_lighting[month]*normalized_hourly_lighting[month][hour]*ltg_ann/days_m[month]
			light_val = lighting_sch[month][hour].to_f
			if light_val > ltg_max
				ltg_max = light_val
				if garage_ltg
					grg_max = normalized_monthly_lighting[month]*normalized_hourly_lighting[month][hour]*garage_ann/days_m[month]
				end
				if outside_ltg 
					outside_max = normalized_monthly_lighting[month]*normalized_hourly_lighting[month][hour]*outside_ann/days_m[month]
				end
			end
		end
	end
	
	
	if fb_ltg
		ltg_tot = ltg_max
		fb_max = ltg_max * (fbfa/cfa)
		ltg_max = ltg_tot-fb_max
	else
		fb_max = 0.0
		ltg_tot = ltg_max
	end
	
	#pull schedule values and gain fractions from sim
	ltg_rad = lightval.Ltg_rad
	ltg_rep = lightval.Ltg_rep
	ltg_vis = lightval.Ltg_vis
	ltg_raf = lightval.Ltg_raf
	
	#get ltg max power
	#ltg_max = ltg_daily * maxval * 1000 * sch_adjust
	
	#add lighting to the selected space(s)
	has_ltg = 0
	replace_ltg = 0
	has_grg_ltg = 0
	replace_grg_ltg = 0
	has_outside_ltg = 0
	replace_outside_ltg = 0
	has_basement_ltg = 0
	replace_basement_ltg = 0
	created = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r or spacehandle == space_type_fb or spacehandle == space_type_grg #add ltg
			space_lights = spaceType.lights
			space_lights.each do |light|
				if light.lightsDefinition.name.get.to_s == "residential_int_lighting"
					has_ltg = 1
					replace_ltg = 1
					runner.registerWarning("This space already has interior lighting, the existing lighting will be replaced with the the currently selected option")
					space_equipment.lightsDefinition.setDesignLevel(ltg_max)
				end
				if light.lightsDefinition.name.get.to_s == "residential_ext_lighting"
					has_outside_ltg = 1
					replace_outside_ltg = 1
					runner.registerWarning("This space already has exterior lighting, the existing lighting will be replaced with the the currently selected option")
					space_equipment.lightsDefinition.setDesignLevel(outside_max)
				end
				if light.lightsDefinition.name.get.to_s == "residential_garage_lighting"
					has_grg_ltg = 1
					replace_grg_ltg = 1
					runner.registerWarning("This space already has garage lighting, the existing lighting will be replaced with the the currently selected option")
					space_equipment.lightsDefinition.setDesignLevel(garage_max)
				end
				if light.lightsDefinition.name.get.to_s == "residential_int_fb_lighting"
					has_basement_ltg = 1
					replace_basement_ltg = 1
					runner.registerWarning("This space already has lighting in the finished basement, the existing lighting will be replaced with the the currently selected option")
					space_equipment.lightsDefinition.setDesignLevel(fb_max)
					
				end
			end
			
			ltg_add = has_ltg + has_outside_ltg + has_grg_ltg + has_basement_ltg

			if garage_ann > 0 and spacehandle == space_type_grg
				has_grg_ltg = 1
			end
			if outside_ann > 0 and spacehandle == space_type_r
				has_outside_ltg = 1
			end
			if ltg_ann > 0 and spacehandle == space_type_r
				has_ltg = 1
			end
			if fb_max > 0 and spacehandle == space_type_fb
				has_basement_ltg = 1
			end
				
			#Add the OS object for the lighting schedule
			ltg_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
			ltg_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
			ltg_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
			time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
			wkdy_ltg_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
			wknd_ltg_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
			day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
			day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
			ltg_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
			ltg_ruleset.setName("Int_lighting_annual_schedule")
				
			for m in 1..12
				date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
				date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
				for w in 1..2
					if w == 1
						wkdy_ltg_rule[m] = OpenStudio::Model::ScheduleRule.new(ltg_ruleset)
						wkdy_ltg_rule[m].setName("ltg_weekday_ruleset#{m}")
						wkdy_ltg_rule
						ltg_wkdy[m] = wkdy_ltg_rule[m].daySchedule
						ltg_wkdy[m].setName("LightingWeekday#{m}")
						for h in 1..24
							time[h] = OpenStudio::Time.new(0,h,0,0)
							val = (lighting_sch[m-1][h-1].to_f)/ltg_tot
							ltg_wkdy[m].addValue(time[h],val)
						end
						wkdy_ltg_rule[m].setApplySunday(false)
						wkdy_ltg_rule[m].setApplyMonday(true)
						wkdy_ltg_rule[m].setApplyTuesday(true)
						wkdy_ltg_rule[m].setApplyWednesday(true)
						wkdy_ltg_rule[m].setApplyThursday(true)
						wkdy_ltg_rule[m].setApplyFriday(true)
						wkdy_ltg_rule[m].setApplySaturday(false)
						wkdy_ltg_rule[m].setStartDate(date_s)
						wkdy_ltg_rule[m].setEndDate(date_e)
								
					elsif w == 2
						wknd_ltg_rule[m] = OpenStudio::Model::ScheduleRule.new(ltg_ruleset)
						wknd_ltg_rule[m].setName("ltg_weekend_ruleset#{m}")
						ltg_wknd[m] = wknd_ltg_rule[m].daySchedule
						ltg_wknd[m].setName("LightingWeekend#{m}")
						for h in 1..24
							time[h] = OpenStudio::Time.new(0,h,0,0)
							val = (lighting_sch[m-1][h-1].to_f)/ltg_tot
							ltg_wknd[m].addValue(time[h],val)
						end
						wknd_ltg_rule[m].setApplySunday(true)
						wknd_ltg_rule[m].setApplyMonday(false)
						wknd_ltg_rule[m].setApplyTuesday(false)
						wknd_ltg_rule[m].setApplyWednesday(false)
						wknd_ltg_rule[m].setApplyThursday(false)
						wknd_ltg_rule[m].setApplyFriday(false)
						wknd_ltg_rule[m].setApplySaturday(true)
						wknd_ltg_rule[m].setStartDate(date_s)
						wknd_ltg_rule[m].setEndDate(date_e)
					end
				end
			end
					
			sumDesSch = ltg_wkdy[6]
			sumDesSch.setName("LightingSummer")
			winDesSch = ltg_wkdy[1]
			winDesSch.setName("LightingWinter")
			ltg_ruleset.setSummerDesignDaySchedule(sumDesSch)
			ltg_ruleset.setWinterDesignDaySchedule(winDesSch)
			#Add electric equipment for the ltg
			
			if has_ltg and spacehandle == space_type_r
				ltg_def = OpenStudio::Model::LightsDefinition.new(model)
				ltg = OpenStudio::Model::Lights.new(ltg_def)
				ltg.setName("residential_interior_lighting")
				ltg.setSpaceType(spaceType)
				ltg_def.setName("residential_interior_lighting")
				ltg_def.setLightingLevel(ltg_max*1000)
				ltg_def.setFractionRadiant(ltg_rad)
				ltg_def.setFractionVisible(ltg_vis)
				ltg_def.setReturnAirFraction(ltg_raf)
				ltg.setSchedule(ltg_ruleset)
			end
				
			if has_grg_ltg and spacehandle == space_type_grg
				grg_ltg_def = OpenStudio::Model::LightsDefinition.new(model)
				grg_ltg = OpenStudio::Model::Lights.new(grg_ltg_def)
				grg_ltg.setName("residential_garage_lighting")
				grg_ltg.setSpaceType(spaceType)
				grg_ltg_def.setName("residential_garage_lighting")
				grg_ltg_def.setLightingLevel(grg_max*1000)
				grg_ltg_def.setFractionRadiant(ltg_rad)
				grg_ltg_def.setFractionVisible(ltg_vis)
				grg_ltg_def.setReturnAirFraction(ltg_raf)
				grg_ltg.setSchedule(ltg_ruleset)
			end
				
			if has_basement_ltg and spacehandle == space_type_fb
				fb_ltg_def = OpenStudio::Model::LightsDefinition.new(model)
				fb_ltg = OpenStudio::Model::Lights.new(fb_ltg_def)
				fb_ltg.setName("residential_basement_lighting")
				fb_ltg.setSpaceType(spaceType)
				fb_ltg_def.setName("residential_basement_lighting")
				fb_ltg_def.setLightingLevel(fb_max*1000)
				fb_ltg_def.setFractionRadiant(ltg_rad)
				fb_ltg_def.setFractionVisible(ltg_vis)
				fb_ltg_def.setReturnAirFraction(ltg_raf)
				fb_ltg.setSchedule(ltg_ruleset)
			end
				
			if has_outside_ltg and spacehandle == space_type_r
				ext_ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
				ext_ltg = OpenStudio::Model::ExteriorLights.new(ext_ltg_def)
				ext_ltg.setName("residential_exterior_lighting")
				#ext_ltg.setSpaceType(spaceType)
				ext_ltg_def.setName("residential_exterior_lighting")
				ext_ltg_def.setDesignLevel(outside_max*1000)
				ext_ltg.setSchedule(ltg_ruleset)
			end
		end
	end

    #reporting final condition of model
	if has_ltg == 1
		if replace_ltg == 1
			runner.registerFinalCondition("The existing lighting has been replaced by one with #{ltg_total} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("Lighting has been added with #{ltg_total} kWh annual energy consumption.")
		end
	else
		runner.registerFinalCondition("Lighting was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialLighting.new.registerWithApplication