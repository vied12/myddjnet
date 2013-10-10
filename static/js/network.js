// Generated by CoffeeScript 1.6.3
var Format, Utils, Widget, start,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

window.network = {};

Widget = window.serious.Widget;

Format = window.serious.format;

Utils = window.serious.Utils;

network.Page = (function(_super) {
  __extends(Page, _super);

  function Page() {
    this.relayout = __bind(this.relayout, this);
    this.bindUI = __bind(this.bindUI, this);
    this.UIS = {
      map: ".Map.primary",
      title: ".Title"
    };
  }

  Page.prototype.bindUI = function(ui) {
    Page.__super__.bindUI.apply(this, arguments);
    this.relayout();
    return $(window).on('resize', this.relayout);
  };

  Page.prototype.relayout = function() {
    var window_height;
    window_height = $(window).height();
    this.uis.title.height(window_height * .2);
    return this.uis.map.height(window_height - this.uis.title.outerHeight(true) - 20);
  };

  return Page;

})(Widget);

network.Map = (function(_super) {
  __extends(Map, _super);

  function Map() {
    this.closeAll = __bind(this.closeAll, this);
    this.allclick = __bind(this.allclick, this);
    this.companyclick = __bind(this.companyclick, this);
    this.personclick = __bind(this.personclick, this);
    this.jppclick = __bind(this.jppclick, this);
    this.renderCountries = __bind(this.renderCountries, this);
    this.hideLegend = __bind(this.hideLegend, this);
    this.showLegend = __bind(this.showLegend, this);
    this.unStickMembers = __bind(this.unStickMembers, this);
    this.stickMembers = __bind(this.stickMembers, this);
    this.closeCircle = __bind(this.closeCircle, this);
    this.openCircle = __bind(this.openCircle, this);
    this.renderEntries = __bind(this.renderEntries, this);
    this.computeEntries = __bind(this.computeEntries, this);
    this.loadedDataCallback = __bind(this.loadedDataCallback, this);
    this.init_size = __bind(this.init_size, this);
    this.bindUI = __bind(this.bindUI, this);
    this.OPTIONS = {
      map_ratio: .5,
      litle_radius: 4,
      big_radius: 20
    };
    this.UIS = {
      panel: '.Panel'
    };
    this.ACTIONS = ['jppclick', 'closeAll', 'companyclick', 'allclick', 'personclick'];
    this.projection = void 0;
    this.groupPaths = void 0;
    this.path = void 0;
    this.force = void 0;
    this.width = void 0;
    this.height = void 0;
    this.hideLegendTimer = void 0;
  }

  Map.prototype.bindUI = function(ui) {
    var graticule;
    Map.__super__.bindUI.apply(this, arguments);
    this.init_size();
    this.svg = d3.select(this.ui.get(0)).insert("svg", ":first-child").attr("width", this.width).attr("height", this.height);
    this.projection = d3.geo.stereographic().scale(this.width).rotate([55, -70]).clipAngle(90).translate([this.width / 2, this.height / 2]);
    this.path = d3.geo.path().projection(this.projection).pointRadius("2");
    this.groupPaths = this.svg.append("g").attr("class", "all-path");
    graticule = d3.geo.graticule();
    this.groupPaths.append("path").datum(graticule).attr("class", "graticule").attr("d", this.path);
    d3.select(window).on('resize', this.init_size);
    return queue().defer(d3.json, "static/data/world.json").defer(d3.json, "static/data/entries.json").await(this.loadedDataCallback);
  };

  Map.prototype.init_size = function() {
    var height, width;
    width = parseInt(d3.select(this.ui.get(0)).style('width'));
    height = parseInt(d3.select(this.ui.get(0)).style('height'));
    if (width != null) {
      this.width = width;
      this.height = this.width * this.OPTIONS.map_ratio;
      if (height > 0 && this.height > height) {
        this.height = height;
        this.width = this.height / this.OPTIONS.map_ratio;
      }
    }
    this.ui.css({
      width: this.width,
      height: this.height
    });
    if (this.projection != null) {
      this.projection.translate([this.width / 2, this.height / 2]).scale(this.width);
    }
    if (this.svg != null) {
      this.svg.style('width', this.width + 'px').style('height', this.height + 'px');
      this.svg.selectAll('.country').attr('d', this.path);
      this.svg.selectAll('.graticule').attr('d', this.path);
    }
    if (this.entries != null) {
      this.entries = this.computeEntries(this.entries);
    }
    if (this.force != null) {
      this.force.stop().start();
    }
    height = this.height * 0.3;
    return this.uis.panel.css({
      height: height,
      width: this.width + 4,
      top: -height - 3
    });
  };

  Map.prototype.loadedDataCallback = function(error, worldTopo, entries) {
    this.countries = topojson.feature(worldTopo, worldTopo.objects.countries);
    this.entries = this.computeEntries(entries);
    this.renderCountries();
    return this.renderEntries();
  };

  Map.prototype.computeEntries = function(entries) {
    var coord, entry, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = entries.length; _i < _len; _i++) {
      entry = entries[_i];
      coord = entry.geo ? this.projection([entry.geo.lon, entry.geo.lat]) : [0, 0];
      entry.qx = coord[0];
      entry.qy = coord[1];
      entry.gx = entry.qx;
      entry.gy = entry.qy;
      entry.radius = this.OPTIONS.litle_radius;
      _results.push(entry);
    }
    return _results;
  };

  Map.prototype.collide = function(alpha) {
    var quadtree;
    quadtree = d3.geom.quadtree(this.entries);
    return function(d) {
      var nx1, nx2, ny1, ny2, r;
      r = d.radius;
      nx1 = d.x - r;
      nx2 = d.x + r;
      ny1 = d.y - r;
      ny2 = d.y + r;
      d.x += (d.gx - d.x) * alpha * 0.1;
      d.y += (d.gy - d.y) * alpha * 0.1;
      return quadtree.visit(function(quad, x1, y1, x2, y2) {
        var l, x, y;
        if (quad.point && quad.point !== d) {
          x = d.x - quad.point.x;
          y = d.y - quad.point.y;
          l = Math.sqrt(x * x + y * y);
          r = d.radius + quad.point.radius;
          if (l < r) {
            l = (l - r) / l * alpha;
            d.x -= x *= l;
            d.y -= y *= l;
            quad.point.x += x;
            quad.point.y += y;
          }
        }
        return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
      });
    };
  };

  Map.prototype.renderEntries = function() {
    var that,
      _this = this;
    that = this;
    this.force = d3.layout.force().nodes(this.entries).gravity(0).charge(0).size([that.width, that.height]).on("tick", function(e) {
      return that.circles.each(that.collide(e.alpha)).attr('transform', function(d) {
        return "translate(" + d.x + ", " + d.y + ")";
      });
    }).start();
    this.circles = this.groupPaths.selectAll(".entity").data(this.entries).enter().append('g').attr('class', function(d) {
      return d.type + " entity";
    }).call(this.force.drag).on("mouseup", function(e, d) {
      var open, ui;
      ui = d3.select(this);
      open = e.radius === that.OPTIONS.big_radius;
      if (open) {
        that.closeCircle(e, ui);
        if (that._previousOver === e) {
          return that.hideLegend(true)(e);
        }
      } else {
        that.openCircle(e, ui, true);
        return that.showLegend(true)(e);
      }
    }).on("mouseover", function(d) {
      if (_this._previousOver !== d) {
        _this.showLegend()(d);
        return _this._previousOver = d;
      }
    }).on("mouseout", this.hideLegend());
    return this.circles.append('circle').attr('r', function(d) {
      return d.radius;
    });
  };

  Map.prototype.openCircle = function(d, e, stick) {
    if (stick == null) {
      stick = false;
    }
    d.radius = this.OPTIONS.big_radius;
    if (d.img != null) {
      e.append('image').attr("width", d.radius * 2).attr("height", d.radius * 2).attr("x", 0 - d.radius).attr("y", 0 - d.radius).style('opacity', 0).attr("xlink:href", function(d) {
        return "static/" + d.img;
      }).transition().duration(250).style('opacity', 1);
    }
    e.select('circle').transition().duration(250).attr("r", function(d) {
      return d.radius;
    });
    if ((d.members != null) && stick) {
      this.stickMembers(d);
    }
    return this.force.start();
  };

  Map.prototype.closeCircle = function(d, e) {
    d.radius = this.OPTIONS.litle_radius;
    e.selectAll('image').remove();
    e.select('circle').transition().duration(250).attr("r", function(d) {
      return d.radius;
    });
    if (d.members != null) {
      this.unStickMembers(d);
    }
    return this.force.start();
  };

  Map.prototype.stickMembers = function(entry) {
    var data, e, _i, _len, _ref, _results;
    _ref = this.circles.filter(function(e) {
      var _ref;
      return _ref = e.id, __indexOf.call(entry.members, _ref) >= 0;
    })[0];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      e = d3.select(e);
      data = e.datum();
      data.gx = entry.gx;
      data.gy = entry.gy;
      _results.push(this.openCircle(data, e));
    }
    return _results;
  };

  Map.prototype.unStickMembers = function(entry) {
    var data, e, _i, _len, _ref, _results;
    this.entries = this.computeEntries(this.entries);
    _ref = this.circles.filter(function(e) {
      var _ref;
      return _ref = e.id, __indexOf.call(entry.members, _ref) >= 0;
    })[0];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      e = d3.select(e);
      data = e.datum();
      _results.push(this.closeCircle(data, e));
    }
    return _results;
  };

  Map.prototype.showLegend = function(blocked) {
    var _this = this;
    if (blocked == null) {
      blocked = false;
    }
    return (function(d, i) {
      _this.legendBlocked = blocked;
      clearTimeout(_this.hideLegendTimer);
      if (d.y > _this.height - _this.uis.panel.height()) {
        _this.uis.panel.addClass('top');
        _this.uis.panel.css('top', -_this.height - 7);
      } else {
        _this.uis.panel.removeClass('top');
        _this.uis.panel.css('top', -_this.uis.panel.height() - 3);
      }
      _this.uis.panel.css('display', 'block');
      return setTimeout(function() {
        _this.uis.panel.removeClass("hidden").find('.title').removeClass("company person event").addClass(d.type).html(d.name || d.title || d.description);
        return _this.uis.panel.find('.description').removeClass("company person event").addClass(d.type).html(d.description || d.title || d.name);
      }, 10);
    });
  };

  Map.prototype.hideLegend = function(force_blocked) {
    var _this = this;
    if (force_blocked == null) {
      force_blocked = false;
    }
    this.legendBlocked = force_blocked ? false : this.legendBlocked;
    return (function(d, i) {
      if (!_this.legendBlocked) {
        _this._previousOver = void 0;
        clearTimeout(_this.hideLegendTimer);
        return _this.hideLegendTimer = setTimeout(function() {
          _this.uis.panel.addClass("hidden");
          return _this.hideLegendTimer = setTimeout(function() {
            return _this.uis.panel.css('display', 'none');
          }, 250);
        }, 100);
      }
    });
  };

  Map.prototype.renderCountries = function() {
    var count, that;
    that = this;
    count = {
      'FRA': 5,
      'ESP': 1,
      'DEU': 2,
      'SWE': 1,
      'USA': 1,
      'CAN': 2,
      'BGR': 1,
      'NET': 1
    };
    return this.groupPaths.selectAll(".country").data(this.countries.features).enter().append("path").attr("d", this.path).attr("class", "country").attr("fill", function(d) {
      return d3.rgb("#5C5D62").darker(count[d.id] * 0.6 | 0);
    });
  };

  Map.prototype.jppclick = function() {
    var that;
    that = this;
    this.closeAll();
    return this.circles.filter(function(d) {
      return d.name === "J++";
    }).each(function(d) {
      return that.openCircle(d, d3.select(this));
    });
  };

  Map.prototype.personclick = function() {
    var that;
    that = this;
    this.closeAll();
    return this.circles.filter(function(d) {
      return d.type === "person";
    }).each(function(d) {
      return that.openCircle(d, d3.select(this));
    });
  };

  Map.prototype.companyclick = function() {
    var that;
    that = this;
    this.closeAll();
    return this.circles.filter(function(d) {
      return d.type === "company";
    }).each(function(d) {
      return that.openCircle(d, d3.select(this));
    });
  };

  Map.prototype.allclick = function() {
    var that;
    that = this;
    return this.circles.each(function(d) {
      return that.openCircle(d, d3.select(this));
    });
  };

  Map.prototype.closeAll = function() {
    var that;
    that = this;
    return this.circles.each(function(d) {
      return that.closeCircle(d, d3.select(this));
    });
  };

  return Map;

})(Widget);

start = function() {
  return $(window).load(function() {
    return Widget.bindAll();
  });
};

start();
