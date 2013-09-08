# -----------------------------------------------------------------------------
# Project : Network
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : MIT licence
# -----------------------------------------------------------------------------
# Creation : 25-Aug-2013
# Last mod : 25-Aug-2013
# -----------------------------------------------------------------------------
window.network = {}

Widget   = window.serious.Widget
# URL      = new window.serious.URL()
Format   = window.serious.format
Utils    = window.serious.Utils

# -----------------------------------------------------------------------------
#
#    Page
#
# -----------------------------------------------------------------------------
class network.Page extends Widget

	constructor: ->
		@UIS = {
			map   : ".Map.primary"
			panel : ".Panel"
		}
	
	bindUI: (ui) =>
		super
		@relayout()
		$(window).on('resize', @relayout)

	relayout: =>
		window_height = $(window).height()
		@uis.panel.height(window_height * .2)
		@uis.map.height(window_height - @uis.panel.outerHeight(true) - 20)


# -----------------------------------------------------------------------------
#
#    Panel
#
# -----------------------------------------------------------------------------
class network.Panel extends Widget

	constructor: ->

# -----------------------------------------------------------------------------
#
#    MAP
#
# -----------------------------------------------------------------------------
class network.Map extends Widget

	constructor: ->
		@OPTIONS =
			map_ratio : .5

		@projection = undefined
		@groupPaths = undefined
		@path       = undefined
		@force      = undefined
		@width      = undefined
		@height     = undefined

	bindUI: (ui) =>
		super
		@init_size()
		@svg    = d3.select(@ui.get(0))
			.insert("svg", ":first-child")
			.attr("width", @width)
			.attr("height", @height)
		# Create projection
		@projection = d3.geo.stereographic()
					.scale(@width)
					.rotate([55,-70])
					.clipAngle(90)
					# .clipAngle(450)
					# .translate([680, 250])
					.translate([@width / 2, @height / 2])
		# Create the globe path
		@path = d3.geo.path().projection(@projection).pointRadius("2") 
		 # Create the group of path and add graticule
		@groupPaths = @svg.append("g").attr("class", "all-path")
		graticule   = d3.geo.graticule()
		@groupPaths.append("path")
					.datum(graticule)
					.attr("class", "graticule")
					.attr("d", @path)
		# binds events
		d3.select(window).on('resize', @init_size)
		queue()
			.defer(d3.json, "/static/data/world.json")
			.defer(d3.json, "/static/data/entries.json")
			.await(@loadedDataCallback)

	init_size: =>
		# adjust things when the window size changes
		width  = parseInt(d3.select(@ui.get(0)).style('width'))
		height = parseInt(d3.select(@ui.get(0)).style('height'))
		if width?
			@width  = width
			@height = @width * @OPTIONS.map_ratio
			if height > 0 and @height > height
				@height = height
				@width  = @height / @OPTIONS.map_ratio
		# update projection
		if @projection?
			@projection
				.translate([@width / 2, @height / 2])
				.scale(@width)
		 # resize the map container
		if @svg?
			@svg
				.style('width' , @width  + 'px')
				.style('height', @height + 'px')
			# resize the map
			@svg.selectAll('.country').attr('d', @path)
			@svg.selectAll('.graticule').attr('d', @path)
		if @entries?
			@entries = @computeEntries(@entries)
		if @force?
			@force.stop().start()

	loadedDataCallback: (error, worldTopo, entries) =>
		@countries = topojson.feature(worldTopo, worldTopo.objects.countries)
		# Cities
		# @cities    = topojson.feature(worldTopo, worldTopo.objects.capitals)
		# @cities.features = @cities.features.filter((d)-> d.id in ['FRA','ESP', 'DEU', "GBR", "SWE"])
		@entries   = @computeEntries(entries)
		@renderCountries()
		@renderEntries()

	computeEntries: (entries) ->
		for entry in entries
			coord = if entry.geo then @projection([entry.geo.lon, entry.geo.lat]) else [0,0]
			entry.qx = coord[0]
			entry.qy = coord[1]
			entry.x = coord[0]
			entry.y = coord[1]
			entry.radius = 6
			entry

	renderEntries: =>
		that   = @
		@force = d3.layout.force()
					.nodes(@entries)
					.gravity(0)
					.charge((d) -> return -Math.pow(d.radius, 2.0) / 6)
					.size([@width, @height])
					.on("tick", (e) =>
						k = e.alpha * 0.1
						@entries.forEach (entry, i) =>
							entry.x += (entry.qx - entry.x) * k
							entry.y += (entry.qy - entry.y) * k
						@circle
							.attr('cx', (d)=>  return d.x)
							.attr('cy', (d)=>  return d.y)
					)
					.start()

		@circle = @groupPaths.selectAll(".entity")
			.data(@entries)
			.enter().append('circle')
			.attr('class', (d) -> return d.type+" entity")
			.attr('r', 6)
			.attr('cx', (d)-> return d.qx)
			.attr('cy', (d)-> return d.qy)
			.call(@force.drag)
			.on("mouseover", @showLegend)
			.on("mouseout", -> d3.selectAll('.legend').remove())
			.on("mousedown", (e,d ) ->
				e.radius = if (Number(d3.select(this).attr('r')) == 6) then 30 else 6
				e.opened = true
				that.force.stop()
				d3.select(this)
					.transition().duration(250)
					.attr('r', (d) -> return d.radius)
				that.force.start()
			)

	showLegend: (d,i) =>
		d3.selectAll('.legend').remove()
		@svg.append("svg:line")
			.attr("class", "legend line")
			.attr("x1", d.x)
			.attr("y1", d.y)
			.attr("x2", d.x + 25)
			.attr("y2", d.y + 25)
		@svg.append("svg:line")
			.attr("class", "legend line")
			.attr("x1", d.x+25)
			.attr("y1", d.y + 25)
			.attr("x2", d.x + 25 * 2)
			.attr("y2", d.y + 25)
		@svg.append("svg:text")
			.attr("class", "legend text")
			.text(d.description || d.title || d.name)
			.attr("x", d.x + 25 * 2)
			.attr("y", d.y + 25)

	renderCountries: =>
		that = this
		@groupPaths.selectAll(".country")
			.data(@countries.features)
			.enter()
				.append("path")
				.attr("d", @path)
				.attr("class", "country")
				.attr("fill", (d) -> return "#5C5D62")

		# Cities
		# @groupPaths.append("path")
		# 	.datum(@cities)
		# 	.attr("d", @path)
		# 	.attr("class", "place")

		# @groupPaths.selectAll(".city")
		# 	.data(@cities.features)
		# 	.enter()
		# 		.append("text")
		# 		.text((d)-> return d.properties.name)
		# 		# .attr("d", @path)
		# 		.attr("class", "city")
		# 		.attr("transform", (d) -> return "translate(" + that.projection(d.geometry.coordinates) + ")")
		# 		.attr("x", (d) -> return if d.geometry.coordinates[0] > -1 then 6 else -6)
		# 		.style("text-anchor", (d) -> return if d.geometry.coordinates[0] > -1 then "start" else "end")

start = ->
	$(window).load ()->
		Widget.bindAll()

start()

# EOF
