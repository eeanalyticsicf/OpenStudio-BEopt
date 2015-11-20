# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class CreateResidentialNeighbors < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Residential Neighbors"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
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
	
	#make a double argument for left neighbor offset
	left_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("left_neighbor_offset", false)
	left_neighbor_offset.setDisplayName("Left Neighbor Offset")
	left_neighbor_offset.setUnits("ft")
	left_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the left (not including eaves). A value of zero indicates no neighbors.")
    left_neighbor_offset.setDefaultValue(0.0)
	args << left_neighbor_offset

	#make a double argument for right neighbor offset
	right_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("right_neighbor_offset", false)
	right_neighbor_offset.setDisplayName("Right Neighbor Offset")
	right_neighbor_offset.setUnits("ft")
	right_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the right (not including eaves). A value of zero indicates no neighbors.")
    right_neighbor_offset.setDefaultValue(0.0)
	args << right_neighbor_offset
	
	#make a double argument for back neighbor offset
	back_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("back_neighbor_offset", false)
	back_neighbor_offset.setDisplayName("Back Neighbor Offset")
	back_neighbor_offset.setUnits("ft")
	back_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the back (not including eaves). A value of zero indicates no neighbors.")
    back_neighbor_offset.setDefaultValue(0.0)
	args << back_neighbor_offset

	#make a double argument for front neighbor offset
	front_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("front_neighbor_offset", false)
	front_neighbor_offset.setDisplayName("Front Neighbor Offset")
	front_neighbor_offset.setUnits("ft")
	front_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the lront (not including eaves). A value of zero indicates no neighbors.")
    front_neighbor_offset.setDefaultValue(0.0)
	args << front_neighbor_offset

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	left_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("left_neighbor_offset",user_arguments),"ft","m").get
	right_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("right_neighbor_offset",user_arguments),"ft","m").get
	back_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("back_neighbor_offset",user_arguments),"ft","m").get
	front_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("front_neighbor_offset",user_arguments),"ft","m").get
	
	if left_neighbor_offset < 0 or right_neighbor_offset < 0 or back_neighbor_offset < 0 or front_neighbor_offset < 0
		runner.registerWarning("You've positioned one or more of the neighbors to be too close to your house.")
	end
	
	least_x = 1000
	greatest_x = -1000
	least_y = 1000
	greatest_y = -1000
	
	# get x and y minima and maxima of wall surfaces
	surfaces = model.getSurfaces
	surfaces.each do |surface|
		if surface.surfaceType == "Wall"
			vertices = surface.vertices
			vertices.each do |vertex|
				if vertex.x > greatest_x
					greatest_x = vertex.x
				end
				if vertex.x < least_x
					least_x = vertex.x
				end
				if vertex.y > greatest_y
					greatest_y = vertex.y
				end
				if vertex.y < least_y
					least_y = vertex.y
				end
			end
		end
	end
	
	# this is maximum building length or width + user specified neighbor offset
	left_offset = ((greatest_x - least_x) + left_neighbor_offset) # TODO: why does positive x in the transformation result in a neg x translation?
	right_offset = -((greatest_x - least_x) + right_neighbor_offset) # TODO: why does negative x in the transformation result in a pos x translation?
	back_offset = -((greatest_y - least_y) + back_neighbor_offset) # TODO: why does negative y in the transformation result in a pos y translation?
	front_offset = ((greatest_y - least_y) + front_neighbor_offset) # TODO: why does positive y in the transformation result in a neg y translation?
				
    spaces = model.getSpaces
    spaces.each do |space|
		shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
		[["left", left_neighbor_offset, left_offset, 0], ["right", right_neighbor_offset, right_offset, 0], ["back", back_neighbor_offset, 0, back_offset], ["front", front_neighbor_offset, 0, front_offset]].each do |dir, neighbor_offset, x_offset, y_offset|
			if neighbor_offset != 0
				new_space = space.clone.to_Space.get
				m = OpenStudio::Matrix.new(4,4,0)
				m[0,0] = 1
				m[1,1] = 1
				m[2,2] = 1
				m[3,3] = 1
				m[0,3] = x_offset
				m[1,3] = y_offset
				m[2,3] = 0
				new_space.changeTransformation(OpenStudio::Transformation.new(m))
				space.changeTransformation(OpenStudio::Transformation.new(m))
				runner.registerInfo("Translated space #{space.name} by #{OpenStudio::convert((x_offset+y_offset).abs,"m","ft").get.round(2)} ft to the #{dir} into neighbor space #{new_space.name}.")
				new_space.surfaces.each do |surface|
					if surface.outsideBoundaryCondition == "Outdoors"
						shading_polygon = OpenStudio::Point3dVector.new
						vertices = surface.vertices
						vertices.each do |vertex|
							shading_polygon << OpenStudio::Point3d.new(vertex.x, vertex.y, vertex.z)
						end
						shading_surface = OpenStudio::Model::ShadingSurface.new(shading_polygon, model)
						shading_surface.setName("#{dir} neighbor shading")
						shading_surface.setShadingSurfaceGroup(shading_surface_group)
						runner.registerInfo("Created shading surface #{shading_surface.name} from surface #{surface.name}.")				
					end
					surface.remove
				end
				new_space.remove
			end
		end
    end

    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialNeighbors.new.registerWithApplication