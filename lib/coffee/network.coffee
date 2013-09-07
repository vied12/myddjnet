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
		@projection = undefined
		@groupPaths = undefined
		@path       = undefined

	bindUI: (ui) =>
		super
		@that = this
		@svg = d3.select(@ui.get(0))
			.insert("svg", ":first-child")
			.attr("width", $(window).width())
			.attr("height", $(window).height())
		# Create projection
		@projection = d3.geo.stereographic()
					.scale(1000)
					.rotate([55,-70])
					.clipAngle(90)
					# .clipAngle(450)
					.translate([680, 250])
					# .clipExtent([[37.944483, 69.617072], [24.491810, 17.534404]])
					# .translate([1000, 500])
					# .precision(0)
		# Create the globe path
		@path = d3.geo.path().projection(@projection)   
		 # Create the group of path and add graticule
		@groupPaths = @svg.append("g").attr("class", "all-path")
		graticule   = d3.geo.graticule()
		@groupPaths.append("path")
					.datum(graticule)
					.attr("class", "graticule")
					.attr("d", @path)
		queue()
			.defer(d3.json, "/static/data/world.json")
			.defer(d3.json, "/static/data/entries.json")
			.await(@loadedDataCallback)

	loadedDataCallback: (error, worldTopo, entries) =>
		countries = topojson.feature(worldTopo, worldTopo.objects.countries).features
		@renderCountries(countries)
		for entry in entries
			coord = if entry.geo then @projection([entry.geo.lon, entry.geo.lat]) else [0,0]
			entry.qx = coord[0]
			entry.qy = coord[1]
			entry.radius = 6
		@renderEntries(entries)

	
	renderEntries:  (entries) =>
		tick = (e) =>
			k = e.alpha * 0.1
			entries.forEach((entry, i) =>
				entry.x += (entry.qx - entry.x) * k
				entry.y += (entry.qy - entry.y) * k
			)
			@circle
				.attr('cx', (d)=>  return d.x)
				.attr('cy', (d)=>  return d.y)

		@force = d3.layout.force()
					.nodes(entries)
					.gravity(0)
					.charge((d) -> return -Math.pow(d.radius, 2.0) / 7)
					.size([$(window).width(), $(window).height()])
					.on("tick", tick)
					.start()

		that = this
		@circle = @groupPaths.selectAll(".entity")
			.data(entries)
			.enter().append('circle')
			.attr('class', 'entity')
			.attr('r', 6)
			.call(@force.drag)
			.on("mousedown", (e,d ) ->
				e.radius = if (Number(d3.select(this).attr('r')) == 6) then 30 else 6
				console.log(e,d)
				that.force.stop()
				d3.select(this)
					# .transition().duration(250)
					.attr('r', (d) -> return d.radius)
				that.force.start()
			)

		# @groupPaths.append('circle')
		# 	.attr('r', 22)
		# 	.attr('fill', 'red')
		# 	.attr('cx', 300)
		# 	.attr('cy', 300)

	renderCountries: (countries) =>
		@groupPaths.selectAll(".country")
			.data(countries)
			.enter()
				.append("path")
				.attr("d", @path)
				.attr("class", "country")
				.attr("fill", (d) -> return "#5C5D62")

start = ->
	$(window).load ()->
		Widget.bindAll()

start()

# EOF
