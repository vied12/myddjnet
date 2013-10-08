#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : 
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 25-Aug-2013
# Last mod : 25-Aug-2013
# -----------------------------------------------------------------------------

from flask import Flask, render_template, request, send_file, \
	send_from_directory, Response, abort, session, redirect, url_for, make_response
import os
# from pymongo        import MongoClient
# from bson.json_util import dumps

app = Flask(__name__)
app.config.from_pyfile("settings.cfg")

# -----------------------------------------------------------------------------
#
# API
#
# -----------------------------------------------------------------------------
# @app.route('/api/data', methods=['get'])
# def data():
# 	return "\n".join(open('data/entries.json').readlines())

# -----------------------------------------------------------------------------
#
# Site pages
#
# -----------------------------------------------------------------------------
@app.route('/')
def index():
	response = make_response(render_template('home.html'))
	return response

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------

if __name__ == '__main__':
	import preprocessing.preprocessing as preprocessing
	import sys
	if len(sys.argv) > 1:
		if sys.argv[1] == "collectstatic":
			preprocessing._collect_static(app)
		if sys.argv[1] == "build":
			from flask_frozen import Freezer
			preprocessing._collect_static(app)
			freezer = Freezer(app)
			freezer.freeze()
		exit()
	else:
		# render ccss, coffeescript and shpaml in 'templates' and 'static' dirs
		preprocessing.preprocess(app, request) 
		# set FileSystemCache instead of Memcache for development
		# cache = werkzeug.contrib.cache.FileSystemCache(os.path.join(app.root_path, "cache"))
		# run application
		app.run()
# EOF
