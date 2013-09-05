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
		@svg = d3.select(@ui.get(0))
			.insert("svg", ":first-child")
			.attr("width", $(window).width())
			.attr("height", $(window).height())
		# Create projection
		@projection = d3.geo.stereographic()
					.scale(1000)
					.rotate([55,-70])
					.clipAngle(90)
					# .translate([0,0])
					# .clipExtent([[37.944483, 69.617072], [24.491810, 17.534404]])
					# .translate([1000, 500])
					# .precision(10)
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
		@renderEntries(entries)

	
	renderEntries:  (entries) =>
		tick = (e) =>
			k = e.alpha * 0.1
			entries.forEach((entry, i) =>
				entry.x += (entry.qx - entry.x) * k
				entry.y += (entry.qy - entry.y) * k
				# o.y += i & 1 ? k : -k
				# o.x += i & 2 ? k : -k
			)
			circle
				.attr('cx', (d)=>  return d.x)
				.attr('cy', (d)=>  return d.y)

		@force = d3.layout.force()
					.nodes(entries)
					.gravity(0)
					.charge(-10)
					.size([$(window).width(), $(window).height()])
					.on("tick", tick)
					.start()

		circle = @groupPaths.selectAll(".entity")
			.data(entries)
			.enter().append('circle')
			.attr('class', 'entity')
			.attr('r', 6)
			.call(@force.drag)
			.on("mousedown", @onhouseover)

	onhouseover: (e) =>
		console.log "hovewr", e
		@groupPaths.select(".dialog")
			.insert('path')
			.attr("class", ".dialog")
			.attr("cx", e.x)
			.attr("cy", e.y)
			.attr("fill", "red")
			.attr("width", 100)
			.attr("height", 100)


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
