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
			title : ".Title"
		}
	
	bindUI: (ui) =>
		super
		@relayout()
		$(window).on('resize', @relayout)

	relayout: =>
		window_height = $(window).height()
		@uis.title.height(window_height * .2)
		@uis.map.height(window_height - @uis.title.outerHeight(true) - 20)

# -----------------------------------------------------------------------------

#    Panel

# -----------------------------------------------------------------------------
# class network.Panel extends Widget

# 	constructor: ->

# 	bindUI: =>
# 		super
# 		console.log('puet')

# 	show: =>


# -----------------------------------------------------------------------------
#
#    MAP
#
# -----------------------------------------------------------------------------
class network.Map extends Widget

	constructor: ->
		@OPTIONS =
			map_ratio    : .5
			litle_radius : 4
			big_radius   : 20

		@UIS = {
			panel : '.Panel'
		}

		@ACTIONS = ['jppclick', 'closeAll', 'companyclick', 'allclick', 'personclick']

		@projection = undefined
		@groupPaths = undefined
		@path       = undefined
		@force      = undefined
		@width      = undefined
		@height     = undefined
		@hideLegendTimer = undefined
		# @panel      = undefined

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
			.defer(d3.json, "static/data/world.json")
			.defer(d3.json, "static/data/entries.json")
			.await(@loadedDataCallback)
		# init panel
		# @ui.append($("<div id='Panel' class='widget' data-widget='network.Panel'></div>"))
		# @panel = Widget.ensureWidget('#Panel')
		# @panel.show()

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
		@ui.css(
			width  : @width
			height : @height
		)
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
		# panel
		height = @height *0.3
		@uis.panel.css(
			height : height
			width  : @width + 4
			top    : -height - 3
			# "margin-left" : @ui.find('svg').offset().left
		)

	loadedDataCallback: (error, worldTopo, entries) =>
		@countries = topojson.feature(worldTopo, worldTopo.objects.countries)
		# Cities
		# @cities    = topojson.feature(worldTopo, worldTopo.objects.capitals)
		# @cities.features = @cities.features.filter((d)-> d.id in ['FRA','ESP', 'DEU', "GBR", "SWE"])
		@entries   = @computeEntries(entries)
		@renderCountries()
		@renderEntries()

	computeEntries: (entries) =>
		for entry in entries
			coord = if entry.geo then @projection([entry.geo.lon, entry.geo.lat]) else [0,0]
			entry.qx = coord[0]
			entry.qy = coord[1]
			entry.gx = entry.qx
			entry.gy = entry.qy
			entry.radius = @OPTIONS.litle_radius
			entry

	collide: (alpha) ->
		quadtree = d3.geom.quadtree(@entries)
		return (d) ->
			r = d.radius
			nx1 = d.x - r
			nx2 = d.x + r
			ny1 = d.y - r
			ny2 = d.y + r
			d.x += (d.gx - d.x) * alpha * 0.1
			d.y += (d.gy - d.y) * alpha * 0.1
			quadtree.visit((quad, x1, y1, x2, y2) ->
				if (quad.point && quad.point != d)
					x = d.x - quad.point.x
					y = d.y - quad.point.y
					l = Math.sqrt(x * x + y * y)
					r = d.radius + quad.point.radius
					if l < r
						l = (l - r) / l * alpha
						d.x -= x *= l
						d.y -= y *= l
						quad.point.x += x
						quad.point.y += y
				return x1 > nx2 \
					|| x2 < nx1 \
					|| y1 > ny2 \
					|| y2 < ny1
			)

	renderEntries: =>
		that   = @
		@force = d3.layout.force()
			.nodes(@entries)
			.gravity(0)
			# .charge((d) -> return if d.type == "company" then -6 else -2000)
			.charge(0)
			.size([that.width, that.height])
			.on("tick", (e) ->
				that.circles
					.each(that.collide(e.alpha))
					.attr('transform', (d)-> "translate("+d.x+", "+d.y+")")
			)
			.start()

		@circles = @groupPaths.selectAll(".entity")
			.data(@entries)
			.enter().append('g')
				.attr('class', (d) -> return d.type+" entity")
				.call(@force.drag)
				.on("mouseup", (e,d) ->
					ui   = d3.select(this)
					open = e.radius == that.OPTIONS.big_radius
					if open
						that.closeCircle(e, ui)
						if that._previousOver == e
							that.hideLegend(true)(e)
					else 
						that.openCircle(e, ui, true)
						that.showLegend(true)(e)
				)
				# .on("mouseover", (d)-> d3.select(this).select('circle').attr('r', d.radius - 2))
				# .on("mouseout", (d)-> d3.select(this).select('circle').attr('r', d.radius))
				.on("mouseover", (d) => if @_previousOver != d then @showLegend()(d); @_previousOver = d)
				.on("mouseout", @hideLegend())

		@circles.append('circle')
			.attr('r', (d) -> return d.radius)

	openCircle: (d, e, stick=false) =>
		d.radius = @OPTIONS.big_radius
		if d.img?
			e.append('image')
				.attr("width", d.radius * 2)
				.attr("height", d.radius * 2)
				.attr("x", 0 - d.radius)
				.attr("y", 0 - d.radius)
				.style('opacity', 0)
				.attr("xlink:href", (d) -> return "static/"+d.img)
				.transition().duration(250).style('opacity', 1)
		e.select('circle')
			.transition().duration(250)
			.attr("r", (d) -> return d.radius)
		if d.members? and stick
			@stickMembers(d)
		@force.start()

	closeCircle: (d, e) =>
		d.radius = @OPTIONS.litle_radius
		e.selectAll('image').remove()
		e.select('circle')
			.transition().duration(250)
			.attr("r", (d) -> return d.radius)
		if d.members?
			@unStickMembers(d)
		@force.start()

	stickMembers: (entry) =>
		# links = []
		for e in @circles.filter((e) -> return e.id in entry.members)[0]
			e = d3.select(e)
			data = e.datum()
			data.gx = entry.gx
			data.gy = entry.gy
			# links.push({source:entry, target:data})
			# @force.links(links)
			@openCircle(data, e)

	unStickMembers: (entry) =>
		@entries = @computeEntries(@entries)
		for e in @circles.filter((e) -> return e.id in entry.members)[0]
			e = d3.select(e)
			data = e.datum()
			@closeCircle(data, e)
		# @force.links([])

	showLegend: (blocked=false) =>
		return ((d,i) =>
			@legendBlocked = blocked
			clearTimeout(@hideLegendTimer)
			if d.y > @height - @uis.panel.height()
				@uis.panel.addClass('top')
				@uis.panel.css('top', -@height - 7)
			else
				@uis.panel.removeClass('top')
				@uis.panel.css('top', -@uis.panel.height() - 3)

			@uis.panel.css('display','block')
			setTimeout(=>
				@uis.panel.removeClass("hidden").find('.title').removeClass("company person event").addClass(d.type).html(d.name || d.title || d.description)
				@uis.panel.find('.description').removeClass("company person event").addClass(d.type).html(d.description || d.title || d.name)
			, 10)
		)

	hideLegend:(force_blocked=false) =>
		@legendBlocked = if force_blocked then false else @legendBlocked
		return ((d,i) =>
			if not @legendBlocked 
				@_previousOver = undefined
				clearTimeout(@hideLegendTimer)
				@hideLegendTimer = setTimeout(=>
					@uis.panel.addClass("hidden")
					@hideLegendTimer = setTimeout(=>
						@uis.panel.css('display','none')
					, 250)
				,100)
		)
		

	renderCountries: =>
		that = this
		count = {
			'FRA' : 5
			'ESP' : 1
			'DEU' : 2
			'SWE' : 1
			'USA' : 1
			'CAN' : 2
			'BGR' : 1
			'NET' : 1
		}
		@groupPaths.selectAll(".country")
			.data(@countries.features)
			.enter()
				.append("path")
				.attr("d", @path)
				.attr("class", "country")
				.attr("fill", (d) -> return d3.rgb("#5C5D62").darker(count[d.id] * 0.6 | 0))
				# .on("mouseup")

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

	jppclick: =>
		that = @
		@closeAll()
		@circles.filter((d) -> d.name=="J++").each((d) ->
			that.openCircle(d, d3.select(this))
		)

	personclick: =>
		that = @
		@closeAll()
		@circles.filter((d) -> d.type=="person").each((d) ->
			that.openCircle(d, d3.select(this))
		)

	companyclick: =>
		that = @
		@closeAll()
		@circles.filter((d) -> d.type=="company").each((d) ->
			that.openCircle(d, d3.select(this))
		)

	allclick: =>
		that = @
		@circles.each((d) -> that.openCircle(d, d3.select(this)))

	closeAll: =>
		that = @
		@circles.each((d) -> that.closeCircle(d, d3.select(this)))

start = ->
	$(window).load ()->
		Widget.bindAll()

start()

# EOF
