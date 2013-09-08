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
#    NAVIGATION
#
# -----------------------------------------------------------------------------
class network.Map extends Widget

	constructor: ->
		@OPTIONS =
			margin    : {top: 10, left: 10, bottom: 10, right: 10}
			map_ratio : .5

		@projection = undefined
		@groupPaths = undefined
		@path       = undefined
		@width      = undefined
		@height     = undefined

	bindUI: (ui) =>
		super
		@width  = parseInt(d3.select(@ui.get(0)).style('width')) - @OPTIONS.margin.left - @OPTIONS.margin.right
		@height = @width * @OPTIONS.map_ratio
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
		@path = d3.geo.path().projection(@projection)   
		 # Create the group of path and add graticule
		@groupPaths = @svg.append("g").attr("class", "all-path")
		graticule   = d3.geo.graticule()
		@groupPaths.append("path")
					.datum(graticule)
					.attr("class", "graticule")
					.attr("d", @path)
		# binds events
		d3.select(window).on('resize', @resize)
		queue()
			.defer(d3.json, "/static/data/world.json")
			.defer(d3.json, "/static/data/entries.json")
			.await(@loadedDataCallback)

	loadedDataCallback: (error, worldTopo, entries) =>
		@countries = topojson.feature(worldTopo, worldTopo.objects.countries).features
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
					.charge((d) -> return -Math.pow(d.radius, 2.0) / 5)
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
			.attr('class', 'entity')
			.attr('r', 6)
			.attr('cx', (d)-> return d.qx)
			.attr('cy', (d)-> return d.qy)
			.call(@force.drag)
			.on("mousedown", (e,d ) ->
				e.radius = if (Number(d3.select(this).attr('r')) == 6) then 30 else 6
				that.force.stop()
				d3.select(this)
					.transition().duration(250)
					.attr('r', (d) -> return d.radius)
				that.force.start()
			)

	renderCountries: =>
		@groupPaths.selectAll(".country")
			.data(@countries)
			.enter()
				.append("path")
				.attr("d", @path)
				.attr("class", "country")
				.attr("fill", (d) -> return "#5C5D62")

	resize: =>
		# adjust things when the window size changes
		@width  = parseInt(d3.select(@ui.get(0)).style('width')) - @OPTIONS.margin.left - @OPTIONS.margin.right
		@height = @width * @OPTIONS.map_ratio
		# update projection
		@projection
			.translate([@width / 2, @height / 2])
			.scale(@width)
		 # resize the map container
		@svg
			.style('width' , @width  + 'px')
			.style('height', @height + 'px')
		# resize the map
		@svg.selectAll('.country').attr('d', @path)
		@svg.selectAll('.graticule').attr('d', @path)
		@entries = @computeEntries(@entries)
		@force.stop().start()

start = ->
	$(window).load ()->
		Widget.bindAll()

start()

# EOF
