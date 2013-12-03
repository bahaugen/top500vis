sigma = 4.0
epsilon = 0.08

window.timestep = 0.3

print_interval = 400

num_particles = 100
particle_mass = 1.0
box_width = 50.0

random = do ->
	seed = 1
	->
		x = Math.sin(seed++) * 10000
		x - Math.floor(x)
	

randomReal = (lower, upper) ->
	random() * (upper - lower) + lower

differencePeriodic = (position1, position2) ->
	x = position2 - position1

	if (x > box_width / 2.0)
		x -= box_width
	else if (x < -box_width / 2.0)
		x += box_width

	x

distanceSqPeriodic = (position1, position2, box_width) ->
	distance_sq = 0.0
	
	for j in [0...3]
		x = differencePeriodic position1[j], position2[j]
		distance_sq += x * x

	distance_sq

randomizeParticlePositions = (positions) ->
	candidate_position = [0.0, 0.0, 0.0]

	for i in [0...num_particles]
		valid_position = false

		while (!valid_position)
			for j in [0...3]
				candidate_position[j] = randomReal(-box_width / 2.0, box_width / 2.0)

			valid_position = true
			for k in [0...i]
				if (distanceSqPeriodic(candidate_position, positions[k], box_width) < sigma * sigma)
					valid_position = false
					break

		for j in [0...3]
			positions[i][j] = candidate_position[j]

	null

computeEnergyBetweenParticles = (position1, position2) ->
	r = Math.sqrt(distanceSqPeriodic(position1, position2, box_width))
	4.0 * epsilon * (Math.pow((sigma / r), 12) - Math.pow((sigma / r), 6))

computeForceOnParticle = (positions, particle_number) ->
	force_delta = [0.0, 0.0, 0.0]
	force = [0.0, 0.0, 0.0]

	for i in [0...num_particles]
		continue if i == particle_number

		force_delta = computeForceBetweenParticles(positions[particle_number], positions[i])
		(force[j] += force_delta[j] for j in [0...3])

	force

computeForceBetweenParticles = (position1, position2) ->
	r_sq = distanceSqPeriodic(position1, position2, box_width)
	r = Math.sqrt(r_sq)

	multiplier = (24.0 * epsilon / r_sq) * (2.0 * Math.pow((sigma / r), 12) - Math.pow((sigma / r), 6))
	(-multiplier * differencePeriodic(position1[j], position2[j]) for j in [0...3])

forceToAcceleration = (force, mass) ->
	(force[j] / mass for j in [0...3])

wrapParticlePositions = (positions) ->
	for i in [0...num_particles]
		for j in [0...3]
			while (positions[i][j] < -box_width / 2.0)
				positions[i][j] += box_width
			while (positions[i][j] > box_width / 2.0)
				positions[i][j] -= box_width
	null

computeParticlePositions = (positions, velocities, accelerations, timestep, new_positions) ->
	for i in [0...num_particles]
		for j in [0...3]
			new_positions[i][j] = positions[i][j] + velocities[i][j]*timestep + 0.5*accelerations[i][j]*timestep*timestep
	wrapParticlePositions(new_positions)
	null

computeParticleAccelerations = (positions, accelerations) ->
	for i in [0...num_particles]
		force = computeForceOnParticle(positions, i)
		acceleration = forceToAcceleration(force, particle_mass)
		for j in [0...3]
			accelerations[i][j] = acceleration[j]
	null

computeParticleVelocities = (velocities, accelerations, new_accelerations, timestep, new_velocities) ->
	for i in [0...num_particles]
		for j in [0...3]
			new_velocities[i][j] = velocities[i][j] + 0.5*(new_accelerations[i][j] + accelerations[i][j])*timestep
	null

takeTimestep = (positions, velocities, accelerations, new_positions, new_velocities, new_accelerations, timestep) ->
	computeParticlePositions(positions, velocities, accelerations, timestep, new_positions)
	computeParticleAccelerations(new_positions, new_accelerations)
	computeParticleVelocities(velocities, accelerations, new_accelerations, timestep, new_velocities)

	null

computePotentialEnergy = (positions) ->
	total_energy = 0.0

	for i in [0...num_particles - 1]
		for k in [(i + 1)...num_particles]
			total_energy += computeEnergyBetweenParticles(positions[i], positions[k])

	total_energy

computeKineticEnergy = (velocities) ->
	total_energy = 0.0

	for i in [0...num_particles]
		velocity_sq = 0.0

		for j in [0...3]
			velocity_sq += velocities[i][j] * velocities[i][j]
		total_energy += 0.5 * particle_mass * velocity_sq

	total_energy

zeroParticleVelocities = (velocities) ->
	for velocity, i in velocities
		velocities[i] = [0.0, 0.0, 0.0]
	null

startSimulation = ->
	positions = ([0.0, 0.0, 0.0] for i in [0...num_particles])
	velocities = ([0.0, 0.0, 0.0] for i in [0...num_particles])
	accelerations = ([0.0, 0.0, 0.0] for i in [0...num_particles])
	new_positions = ([0.0, 0.0, 0.0] for i in [0...num_particles])
	new_velocities = ([0.0, 0.0, 0.0] for i in [0...num_particles])
	new_accelerations = ([0.0, 0.0, 0.0] for i in [0...num_particles])

	randomizeParticlePositions positions
	computeParticleAccelerations positions, accelerations

	t = 0
	timestepFunction = ->
		if (t % print_interval == 0)
			total_potential_energy = computePotentialEnergy positions
			total_kinetic_energy = computeKineticEnergy velocities
			total_energy = total_potential_energy + total_kinetic_energy

		takeTimestep positions, velocities, accelerations, new_positions, new_velocities, new_accelerations, timestep
		for i in [0...num_particles]
			for j in [0...3]
				positions[i][j] = new_positions[i][j]
				velocities[i][j] = new_velocities[i][j]
				accelerations[i][j] = new_accelerations[i][j]
		#new_positions = ([0.0, 0.0, 0.0] for i in [0...num_particles])
		#new_velocities = ([0.0, 0.0, 0.0] for i in [0...num_particles])
		#new_accelerations = ([0.0, 0.0, 0.0] for i in [0...num_particles])

		t += 1
	
		[total_energy, total_potential_energy, total_kinetic_energy]

	[positions, velocities, timestepFunction]

atomProperties =
	atomicVDWRadius:
		H:	1.2
		He:	1.4
		Li:	1.82
		Be:	1.53
		B:	1.92
		C:	1.7
		N:	1.55
		O:	1.52
		F:	1.47
		Ne:	1.54
		Na:	2.27
		Mg:	1.73
		Al:	1.84
		Si:	2.1
		P:	1.8
		S:	1.8
		Cl:	1.75
		Ar:	1.88
		K:	2.75
		Ca:	2.31
		Sc:	2.11
		Ti:	1.5
		V:	1.5
		Cr:	1.5
		Mn:	1.5
		Fe:	1.5
		Co:	1.5
		Ni:	1.63
		Cu:	1.4
		Zn:	1.39
		Ga:	1.87
		Ge:	2.11
		As:	1.85
		Se:	1.9
		Br:	1.85
		Kr:	2.02
		Rb:	3.03
		Sr:	2.49
		Y:	1.5
		Zr:	1.5
		Nb:	1.5
		Mo:	1.5
		Tc:	1.5
		Ru:	1.5
		Rh:	1.5
		Pd:	1.63
		Ag:	1.72
		Cd:	1.58
		In:	1.93
		Sn:	2.17
		Sb:	2.06
		Te:	2.06
		I:	1.98
		Xe:	2.16
		Cs:	3.43
		Ba:	2.68
		La:	1.5
		Ce:	1.5
		Pr:	1.5
		Nd:	1.5
		Pm:	1.5
		Sm:	1.5
		Eu:	1.5
		Gd:	1.5
		Tb:	1.5
		Dy:	1.5
		Ho:	1.5
		Er:	1.5
		Tm:	1.5
		Yb:	1.5
		Lu:	1.5
		Hf:	1.5
		Ta:	1.5
		W:	1.5
		Re:	1.5
		Os:	1.5
		Ir:	1.5
		Pt:	1.75
		Au:	1.66
		Hg:	1.55
		Tl:	1.96
		Pb:	2.02
		Bi:	2.07
		Po:	1.97
		At:	2.02
		Rn:	2.2
		Fr:	3.48
		Ra:	2.83
		Ac:	1.5
		Th:	1.5
		Pa:	1.5
		U:	1.86
		Np:	1.5
		Pu:	1.5
		Am:	1.5
		Cm:	1.5
		Bk:	1.5
		Cf:	1.5
		Es:	1.5
		Fm:	1.5
		Md:	1.5
		No:	1.5
		Lr:	1.5
		Rf:	1.5
		Db:	1.5
		Sg:	1.5
		Bh:	1.5
		Hs:	1.5
		Mt:	1.5
		Ds:	1.5
		Rg:	1.5
		Cn:	1.5
		Uut:	1.5
		Fl:	1.5
		Uup:	1.5
		Lv:	1.5
		Uus:	1.5
		Uuo:	1.5
	color:
		H: 0xffffff
		He: 0xd9ffff
		Li: 0xcc80ff
		Be: 0xc2ff00
		B: 0xffb5b5
		C: 0x909090
		N: 0x3050f8
		O: 0xff0d0d
		F: 0x90e050
		Ne: 0xb3e3f5
		Na: 0xab5cf2
		Mg: 0x8aff00
		Al: 0xbfa6a6
		Si: 0xf0c8a0
		P: 0xff8000
		S: 0xffff30
		Cl: 0x1ff01f
		Ar: 0x80d1e3
		K: 0x8f40d4
		Ca: 0x3dff00
		Sc: 0xe6e6e6
		Ti: 0xbfc2c7
		V: 0xa6a6ab
		Cr: 0x8a99c7
		Mn: 0x9c7ac7
		Fe: 0xe06633
		Co: 0xf090a0
		Ni: 0x50d050
		Cu: 0xc88033
		Zn: 0x7d80b0
		Ga: 0xc28f8f
		Ge: 0x668f8f
		As: 0xbd80e3
		Se: 0xffa100
		Br: 0xa62929
		Kr: 0x5cb8d1
		Rb: 0x702eb0
		Sr: 0x00ff00
		Y: 0x94ffff
		Zr: 0x94e0e0
		Nb: 0x73c2c9
		Mo: 0x54b5b5
		Tc: 0x3b9e9e
		Ru: 0x248f8f
		Rh: 0x0a7d8c
		Pd: 0x006985
		Ag: 0xc0c0c0
		Cd: 0xffd98f
		In: 0xa67573
		Sn: 0x668080
		Sb: 0x9e63b5
		Te: 0xd47a00
		I: 0x940094
		Xe: 0x429eb0
		Cs: 0x57178f
		Ba: 0x00c900
		La: 0x70d4ff
		Ce: 0xffffc7
		Pr: 0xd9ffc7
		Nd: 0xc7ffc7
		Pm: 0xa3ffc7
		Sm: 0x8fffc7
		Eu: 0x61ffc7
		Gd: 0x45ffc7
		Tb: 0x30ffc7
		Dy: 0x1fffc7
		Ho: 0x00ff9c
		Er: 0x00e675
		Tm: 0x00d452
		Yb: 0x00bf38
		Lu: 0x00ab24
		Hf: 0x4dc2ff
		Ta: 0x4da6ff
		W: 0x2194d6
		Re: 0x267dab
		Os: 0x266696
		Ir: 0x175487
		Pt: 0xd0d0e0
		Au: 0xffd123
		Hg: 0xb8b8d0
		Tl: 0xa6544d
		Pb: 0x575961
		Bi: 0x9e4fb5
		Po: 0xab5c00
		At: 0x754f45
		Rn: 0x428296
		Fr: 0x420066
		Ra: 0x007d00
		Ac: 0x70abfa
		Th: 0x00baff
		Pa: 0x00a1ff
		U: 0x008fff
		Np: 0x0080ff
		Pu: 0x006bff
		Am: 0x545cf2
		Cm: 0x785ce3
		Bk: 0x8a4fe3
		Cf: 0xa136d4
		Es: 0xb31fd4
		Fm: 0xb31fba
		Md: 0xb30da6
		No: 0xbd0d87
		Lr: 0xc70066
		Rf: 0xcc0059
		Db: 0xd1004f
		Sg: 0xd90045
		Bh: 0xe00038
		Hs: 0xe6002e
		Mt: 0xeb0026
		Ds: 0xeb0026
		Rg: 0xeb0026

getAtomProperty = (property, atomType) ->
	if !atomProperties[property][atomType]?
		alert "No atom property '#{property}' for atom type '#{atomType}' in database!"
		null
	else
		atomProperties[property][atomType]

round = (num, places) -> Math.round(num * Math.pow(10, places)) / Math.pow(10, places)

calculateTotalTriangles = (objectList) ->
	# objectList is an array, where each value is a map with keys 'type', 'geometry', and 'instances'
	# Ex: [{type: 'sphere', geometry: sphere, instances: [{position: ..., rotation: ...,]}, ...]
	# 'Instances' is an array of instances of that geometry, where each value of the array
	# is a map whose keys are a particular instance property (position, rotation, etc...)

	numTriangles = 0
	for object in objectList
		numTriangles += object.instances.length * object.geometry.faces.length
	numTriangles

createBufferedGeometry = (objectList) ->
	numTriangles = calculateTotalTriangles objectList

	geometry = new THREE.BufferGeometry()
	geometry.attributes =
		position:
			itemSize: 3
			array: new Float32Array 3 * 3 * numTriangles
			numItems: 3 * 3 * numTriangles
		normal:
			itemSize: 3
			array: new Float32Array 3 * 3 * numTriangles
			numItems: 3 * 3 * numTriangles
		color:
			itemSize: 3
			array: new Float32Array 3 * 3 * numTriangles
			numItems: 3 * 3 * numTriangles
	geometry
	

augmentObjectList = (objectList, sphereList, cylinderList) ->
	for sphereType in sphereList
		sphereGeometry = new THREE.SphereGeometry sphereType.radius, 20, 20
		objectList.push
			type: 'sphere'
			geometry: sphereGeometry
			color: sphereType.color
			instances: ({position: position} for position in sphereType.positions)
	for cylinderType, ind in cylinderList
		if ind == 0
			cylinderGeometry = new THREE.CylinderGeometry 0.1, 0.1, 50, 8, 1, false

		if ind == 1
			cylinderGeometry = new THREE.CylinderGeometry 0.1, 0.1, 50, 8, 1, false
			m = new THREE.Matrix4()
			m1 = new THREE.Matrix4()
			m2 = new THREE.Matrix4()
			m3 = new THREE.Matrix4()
			alpha = Math.PI / 2
			beta = 0
			gamma = 0
			m1.makeRotationX alpha
			m2.makeRotationY beta
			m3.makeRotationZ gamma
			m.multiplyMatrices m1, m2
			m.multiply m3
			cylinderGeometry.applyMatrix m

		if ind == 2
			cylinderGeometry = new THREE.CylinderGeometry 0.1, 0.1, 50, 8, 1, false
			m = new THREE.Matrix4()
			m1 = new THREE.Matrix4()
			m2 = new THREE.Matrix4()
			m3 = new THREE.Matrix4()
			alpha = 0
			beta = 0
			gamma = Math.PI / 2
			m1.makeRotationX alpha
			m2.makeRotationY beta
			m3.makeRotationZ gamma
			m.multiplyMatrices m1, m2
			m.multiply m3
			cylinderGeometry.applyMatrix m

		objectList.push
			type: 'cylinder'
			geometry: cylinderGeometry
			color: cylinderType.color
			instances: ({position: position} for position in cylinderType.positions)
	null


addObjectsToGeometry = (geometry, objectList) ->
	index = 0
	for object in objectList
		for instance in object.instances
			index = addObjectToGeometry geometry, index, object.type, object.color, object.geometry, instance
	null
	

addObjectToGeometry = (geometry, index, objectType, objectColor, objectGeometry, instance) ->
	positions = geometry.attributes.position.array
	normals = geometry.attributes.normal.array
	colors = geometry.attributes.color.array
	
	objectTypes =
		sphere: ->
			position = instance.position
			r = objectGeometry.radius
			vertices = objectGeometry.vertices
			color = objectColor

			for face, i in objectGeometry.faces
				j = index + 9*i

				positions[j + 0] = position.x + vertices[face.a].x
				positions[j + 1] = position.y + vertices[face.a].y
				positions[j + 2] = position.z + vertices[face.a].z

				positions[j + 3] = position.x + vertices[face.b].x
				positions[j + 4] = position.y + vertices[face.b].y
				positions[j + 5] = position.z + vertices[face.b].z

				positions[j + 6] = position.x + vertices[face.c].x
				positions[j + 7] = position.y + vertices[face.c].y
				positions[j + 8] = position.z + vertices[face.c].z

				normals[j + 0] = face.vertexNormals[0].x
				normals[j + 1] = face.vertexNormals[0].y
				normals[j + 2] = face.vertexNormals[0].z

				normals[j + 3] = face.vertexNormals[1].x
				normals[j + 4] = face.vertexNormals[1].y
				normals[j + 5] = face.vertexNormals[1].z

				normals[j + 6] = face.vertexNormals[2].x
				normals[j + 7] = face.vertexNormals[2].y
				normals[j + 8] = face.vertexNormals[2].z

				colors[j + 0] = color.r
				colors[j + 1] = color.g
				colors[j + 2] = color.b
				
				colors[j + 3] = color.r
				colors[j + 4] = color.g
				colors[j + 5] = color.b
			
				colors[j + 6] = color.r
				colors[j + 7] = color.g
				colors[j + 8] = color.b

			index + 9 * objectGeometry.faces.length
		cylinder: ->
			position = instance.position
			vertices = objectGeometry.vertices
			color = objectColor

			for face, i in objectGeometry.faces
				j = index + 9*i

				positions[j + 0] = position.x + vertices[face.a].x
				positions[j + 1] = position.y + vertices[face.a].y
				positions[j + 2] = position.z + vertices[face.a].z

				positions[j + 3] = position.x + vertices[face.b].x
				positions[j + 4] = position.y + vertices[face.b].y
				positions[j + 5] = position.z + vertices[face.b].z

				positions[j + 6] = position.x + vertices[face.c].x
				positions[j + 7] = position.y + vertices[face.c].y
				positions[j + 8] = position.z + vertices[face.c].z

				normals[j + 0] = face.vertexNormals[0].x
				normals[j + 1] = face.vertexNormals[0].y
				normals[j + 2] = face.vertexNormals[0].z

				normals[j + 3] = face.vertexNormals[1].x
				normals[j + 4] = face.vertexNormals[1].y
				normals[j + 5] = face.vertexNormals[1].z

				normals[j + 6] = face.vertexNormals[2].x
				normals[j + 7] = face.vertexNormals[2].y
				normals[j + 8] = face.vertexNormals[2].z

				colors[j + 0] = color.r
				colors[j + 1] = color.g
				colors[j + 2] = color.b
				
				colors[j + 3] = color.r
				colors[j + 4] = color.g
				colors[j + 5] = color.b
			
				colors[j + 6] = color.r
				colors[j + 7] = color.g
				colors[j + 8] = color.b

			index + 9 * objectGeometry.faces.length

	objectTypes[objectType]()

renderLoop = (renderer, scene, camera, fpsFunc, loopFuncs) ->
	clock = new THREE.Clock()
	tick = 0

	render = (currentLoopTime) ->
		fps = round(1 / clock.getDelta(), 0)
		tick = (tick + 1) % 10
		if tick == 0
			fpsFunc fps
		previousLoopTime = currentLoopTime

		func(clock.getElapsedTime()) for func in loopFuncs

		renderer.render scene, camera
		requestAnimationFrame render


onWindowResize = (renderer, scene, camera) -> ->
	newWidth = $(renderer.domElement).parent().width()
	newHeight = $(renderer.domElement).parent().height()
	newAspectRatio = newWidth / newHeight

	if camera instanceof THREE.OrthographicCamera
		m = 12
		camera.left = -m  * newAspectRatio
		camera.right = m * newAspectRatio
		camera.top = m
		camera.bottom = -m
		camera.near = -1000
		camera.far = 1000
	else if camera instanceof THREE.PerspectiveCamera
		camera.fov = 20
		camera.aspect = newAspectRatio
		camera.near = 0.1
		camera.far = 1000

	camera.updateProjectionMatrix()

	renderer.setSize newWidth, newHeight
	renderer.render scene, camera


createControls = (renderer, scene, camera, mesh) ->
	canvas = renderer.domElement
	canvasWidth = $(canvas).width()
	canvasHeight = $(canvas).height()

	mouseStartCoords = new THREE.Vector2()
	mouseLastCoords = new THREE.Vector2()
	mouseCurrentCoords = new THREE.Vector2()
	mouseDelta = new THREE.Vector2()

	cameraStartCoords = new THREE.Vector3()
	cameraStartUpVector = new THREE.Vector3()

	meshStartCoords = new THREE.Vector3()
	meshStartRotation = new THREE.Euler()

	target = new THREE.Vector3(0, 0, 0)

	transformType = null

	axisVector = new THREE.Vector3()
	vectorCameraTarget = new THREE.Vector3()

	transforms =
		translation: (mouseDelta) ->
			camera.position.setX cameraStartCoords.x - mouseDelta.x/10
			camera.position.setY cameraStartCoords.y - mouseDelta.y/10
			camera.updateProjectionMatrix()

		zoom: (wheelDelta) ->
			vectorCameraTarget.subVectors(cameraStartCoords, mesh.position).normalize()
			translationAxis = mesh.worldToLocal(vectorCameraTarget).normalize()
			#console.log translationAxis
			mesh.translateOnAxis(translationAxis, wheelDelta/150)
			#console.log mesh.rotation

		rotation: (mouseCurrentCoords) ->
			mouseDelta.subVectors mouseCurrentCoords, mouseLastCoords
			vectorCameraTarget.subVectors(cameraStartCoords, mesh.position).normalize()
			axisVector.crossVectors(vectorCameraTarget, cameraStartUpVector).normalize()
			mouseDeltaMagnitude = mouseDelta.length() / 50
			mouseDeltaAngle = Math.atan2(-mouseDelta.y, mouseDelta.x)
			rotationAxis = axisVector.clone().applyAxisAngle(vectorCameraTarget, mouseDeltaAngle - Math.PI / 2).normalize()
			rotationAxis.copy mesh.worldToLocal(rotationAxis)
			mesh.rotateOnAxis(rotationAxis, mouseDeltaMagnitude)
			mouseLastCoords.copy mouseCurrentCoords
			#console.log mesh.rotation

		circle: (mouseCurrentCoords) ->
			mouseDelta.subVectors mouseCurrentCoords, mouseStartCoords
			vectorCameraTarget.subVectors(cameraStartCoords, mesh.position).normalize()
			mouseDeltaAngle = Math.atan2((mouseStartCoords.y - canvasHeight/2), (mouseStartCoords.x - canvasWidth/2)) - Math.atan2((mouseCurrentCoords.y - canvasHeight/2), (mouseCurrentCoords.x - canvasWidth/2))
			mesh.rotation.copy(meshStartRotation)
			rotationAxis = new THREE.Vector3()
			rotationAxis.copy mesh.worldToLocal(vectorCameraTarget)
			mesh.rotateOnAxis(vectorCameraTarget, mouseDeltaAngle)
			
	onMouseWheel = (event) ->
		cameraStartCoords.copy camera.position
		event.preventDefault()
		transforms['zoom'](event.originalEvent.wheelDelta)

		renderer.render scene, camera

	bodyMouseUp = ->
		$('body').off 'mouseup'
		$(canvas).off 'mousemove'

	canvasMouseMove = (event) ->
		event.preventDefault()
		mouseCurrentCoords.set event.offsetX, event.offsetY

		transforms[transformType](mouseCurrentCoords)
		renderer.render scene, camera

	canvasMouseDown = (event) ->
		event.preventDefault()

		$(canvas).mousemove canvasMouseMove
		$('body').mouseup bodyMouseUp

		if event.shiftKey
			transformType = 'circle'
		else
			transformType = 'rotation'

		mouseStartCoords.set event.offsetX, event.offsetY
		mouseLastCoords.set event.offsetX, event.offsetY
		meshStartCoords.copy mesh.position
		meshStartRotation.copy mesh.rotation
		cameraStartCoords.copy camera.position
		cameraStartUpVector.copy camera.up
		canvasWidth = $(canvas).width()
		canvasHeight = $(canvas).height()

	$(canvas).mousedown canvasMouseDown
	#$('body').on('mousewheel', onMouseWheel)
	#$('body').on('DOMMouseScroll', onMouseWheel)

init = ->
	scene = new THREE.Scene()
	#camera = new THREE.OrthographicCamera()
	camera = new THREE.PerspectiveCamera()
	camera.position.set 0, 0, 200

	scene.add new THREE.AmbientLight 0xFFFFFF

	light1 = new THREE.DirectionalLight 0xffffff, 0.5
	light1.position.set 100, 100, 0
	scene.add light1

	light2 = new THREE.DirectionalLight 0xffffff, 1.5
	light2.position.set -100, 100, 0
	scene.add light2

	#fog = new THREE.Fog(0x000000, 0.1, 2000)
	#fog.color.setHSL(0.51, 0.6, 0.6)
	#scene.add fog

	material = new THREE.MeshPhongMaterial
		color: 0x666666
		ambient: 0x333333
		specular: 0x333333
		shininess: 30
		side: THREE.DoubleSide
		vertexColors: true

	renderer = new THREE.WebGLRenderer
		antialias: true
		clearColor: 0x050505
		clearAlpha: 1
		gammaInput: true
		gammaOutput: true
		physicallyBasedShading: true
		shadwMapEnabled: false

	$ ->
		$('#renderBox').append renderer.domElement
		$(window).resize onWindowResize(renderer, scene, camera)

	#readXYZFile 'r7.xyz', (atoms) ->
	[atomCoords, atomVelocities, takeSimulationStep] = startSimulation()
	numAtoms = atomCoords.length
	do ->
		sphereTypes = {}
		sphereTypes['C'] ?=
			radius: 0.6 * getAtomProperty 'atomicVDWRadius', 'C'
			color: new THREE.Color 0xaaffaa
			#color: new THREE.Color getAtomProperty('color', 'H')
			positions: []
		for coord, i in atomCoords
			sphereTypes['C'].positions.push new THREE.Vector3 coord[0], coord[1], coord[2]

		cylinderColor = new THREE.Color 0xaaffaa
		cylinderTypes = {}
		cylinderTypes['up'] =
			color: cylinderColor
			positions: [
				new THREE.Vector3(-25, 0, -25)
				new THREE.Vector3(-25, 0, 25)
				new THREE.Vector3(25, 0, -25)
				new THREE.Vector3(25, 0, 25)
				]
		cylinderTypes['across'] =
			color:  cylinderColor
			positions: [
				new THREE.Vector3(-25, -25, 0)
				new THREE.Vector3(-25, 25, 0)
				new THREE.Vector3(25, -25, 0)
				new THREE.Vector3(25, 25, 0)
				]
		cylinderTypes['back'] =
			color: cylinderColor
			positions: [
				new THREE.Vector3(0, 25, -25)
				new THREE.Vector3(0, -25, -25)
				new THREE.Vector3(0, 25, 25)
				new THREE.Vector3(0, -25, 25)
				]

		sphereList = (sphereType for sphereTypeName, sphereType of sphereTypes)
		cylinderList = (cylinderType for cylinderTypeName, cylinderType of cylinderTypes)
		objectList = []
		augmentObjectList objectList, sphereList, cylinderList

		geometry = createBufferedGeometry objectList
		geometry.dynamic = true
		addObjectsToGeometry geometry, objectList
		geometry.computeBoundingSphere()

		mesh = new THREE.Mesh geometry, material
		scene.add mesh

		window.glob = ->
			window.mesh = mesh
			window.scene = scene
			window.camera = camera
			window.renderer = renderer
			null

		$ ->
			createControls(renderer, scene, camera, mesh)
			$(window).resize()
			numVerticesAtom = 6840
			#numVerticesAtom = geometry.attributes.position.array.length / numAtoms
			vertexOffset = (atomCoords[0][k % 3] - geometry.attributes.position.array[k] for k in [0...numVerticesAtom])
			colorOffset = (geometry.attributes.color.array[k] for k in [0...numVerticesAtom])

			simulate = -> window.setTimeout (->
				takeSimulationStep()
				simulate()
				), 0
			simulate()

					
			renderLoopFuncs = [
				->
					for i in [0...numAtoms]
						atomSpeedSq = atomVelocities[i][0]*atomVelocities[i][0] + atomVelocities[i][1]*atomVelocities[i][1] + atomVelocities[i][2]*atomVelocities[i][2]
						atomSpeed = Math.pow(4*(atomSpeedSq + 0.05), 0.7) + 0.05
						for k in [0...numVerticesAtom]
							geometry.attributes.position.array[numVerticesAtom*i + k] = atomCoords[i][k % 3] + vertexOffset[k]
							geometry.attributes.color.array[numVerticesAtom*i + k] = Math.max(0.4, Math.min(atomSpeed * colorOffset[k], 1.0))
					geometry.attributes.position.needsUpdate = true
					geometry.attributes.color.needsUpdate = true
			]
			startRenderLoop = renderLoop renderer, scene, camera, (->), renderLoopFuncs
			startRenderLoop()

init()
