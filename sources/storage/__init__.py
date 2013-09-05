#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : Serious Toolkit
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 16-Oct-2012
# Last mod : 27-Oct-2012
# -----------------------------------------------------------------------------

import inspect, model.models, store_model

class Interface:
	"""

	Interface: interface for persistance.
	TODO: [X] generate dynamically all classes from model package.
	      [ ] Handle relations between models
	      [ ] Handle binary files

	"""
	instance = None

	def __init__(self, database):
		"""

		Generate an interface for each Model implementation

		"""
		for name, obj in inspect.getmembers(model.models, inspect.isclass):
			if obj.__bases__ and obj.__bases__[0].__name__ == "Model":
				setattr(self, name, store_model.ModelForShoveInterface("mongodb://localhost:27017/%s/%s" % (database, name.lower())))

if __name__ == "__main__":
	interface = Interface("test1")
	news      = model.models.News({"title":"titre", "content":"hola"}) 
	interface.News.save(news)
	print interface.News.get()