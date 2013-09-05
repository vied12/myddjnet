#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : Serious Toolkit
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Oct-2012
# Last mod : 27-Oct-2012
# -----------------------------------------------------------------------------
__version__ = '0.1'

import shove, uuid, copy

class ModelForShoveInterface():
	"""

	Shove Interface for Models

	"""

	def __init__(self, cache_uri=""):
		self.connection = shove.Shove(cache_uri, optimize=False)

	def save(self, obj):
		"""

		Save and sync the given object

		"""
		if not getattr(obj, "id", None):
			obj.id = str(uuid.uuid4())
		self.connection[obj.id] = obj
		self.sync()

	def remove(self, obj_or_id):
		"""

		remove and sync the given object from id or object itself

		"""
		if type(obj_or_id) is str or type(obj_or_id) == unicode:
			del self.connection[obj_or_id]
		else:
			if not getattr(obj_or_id, "id", None):
				raise Exception("unknown object", obj_or_id)
			del self.connection[obj_or_id.id]
		self.sync()

	def sync(self):
		"""

		sync the collection

		"""
		self.connection.sync()

	def get(self, id=None, sort=None, ln=None):
		"""

		Retrive an object if id is given. Otherwise retrive all the objects.
		If language is given, all fields specified in i18n will be translated
		TODO: handle the sort parameter

		"""
		def _translate(obj, ln):
			""" translate all fields in i18n attribute """
			obj_copy = copy.copy(obj)
			for field in obj.structure:
				if field in obj.i18n:
					value = getattr(obj, field, None)
					if value and type(value) is dict:
						if value.get(ln):
							setattr(obj_copy, field, value[ln])
						else: # default language
							setattr(obj_copy, field, value["en"])
			return obj_copy
		# FIXME: handle exception KeyError
		if id and id != "all":
			if ln:
				return _translate(self.connection[id], ln)
			else:
				return self.connection[id]
		else:
			collection = self.connection
			if ln:
				return [_translate(_, ln) for _ in collection.values()]
			else:
				return list(collection.values())