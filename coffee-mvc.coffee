class Dictionary
	constructor: (@values = {}) ->

	validate: (value) ->
		true

	store: (name, value) ->
		if @validate value
			@values[name] = value 
		else
			throw new Error 'value not validated'
	
	lookup: (name) ->
		@values[name]
	
	contains: (name) ->
		Object::hasOwnProperty.call(@values , name) and
		Object::propertyIsEnumerable.call(@values , name)

	each: (action) ->
		for own property , value of @values
			action property , value

	remove: (name) ->
		delete @values[name] if @values[name]?

class Route
	constructor: (@controller, @view) ->

class RoutesCollection extends Dictionary
	validate: (value) ->
		value.constructor.name is 'Route'

class ControllerCollection extends Dictionary
	validate: (value) ->
		typeof value is 'function'

class Scope
	watch: (prop, handler) ->
		getter = ->
			newval

		setter = (val) ->
			[oldval, newval] = [newval, val]
			handler.call this, prop, oldval, val

		if delete this[prop]
			Object.defineProperty this, prop, {
				get: getter
				set: setter
			}
		else if Object.prototype.__defineGetter__ and Object.prototype.__defineSetter__ 
			Object.prototype.__defineGetter__.call this, prop, getter
			Object.prototype.__defineSetter__.call this, prop, setter

class ScopeCollection extends Dictionary
	validate: (value) ->
		value.constructor.name is 'Scope'

class CoffeeMVC
	constructor: ->
		@routes = new RoutesCollection()
		@controllers = new ControllerCollection()

	scopes: new ScopeCollection()

	bootstrap: ->
		@readRoute()
		@handleRoute()

	readRoute: ->
		routeComponents = window.location.hash.split '/'
		@currentRoute = routeComponents[0].replace '#', ''
		@routeArgs = routeComponents.splice 1

	handleRoute: ->
		@config = { 
			controller: @routes.lookup('default').controller
			view: @routes.lookup('default').view
			args: @routeArgs 
		}
		if (r = @routes.lookup @currentRoute )?
			@config.controller = r.controller
			@config.view = r.view
		@routes.each (name, route) ->
			document.getElementById( route.view.substr 0, route.view.length-1 ).innerHTML = ''
		if !(@scopes.lookup @config.controller )?
			@scopes.store @config.controller, new Scope()
		@scopes.store @config.controller, @controllers.lookup(@config.controller)(@config.args, @scopes.lookup @config.controller )
		for  model in @scopes.lookup @config.controller
			@scopes.lookup(@config.controller).watch model, -> CoffeeMVC.compile()
		@compile()

	compile: ->
		view = document.getElementById(@config.view).text
		currentView = doT.template view, undefined, header: view
		document.getElementById(@config.view.substr 0, @config.view.length-1 ).innerHTML = currentView @scopes.lookup @config.controller

(exports ? this).Dictionary = Dictionary
(exports ? this).Scope = Scope
(exports ? this).ScopeCollection = ScopeCollection
(exports ? this).RoutesCollection = RoutesCollection
(exports ? this).Route = Route
(exports ? this).ControllerCollection = ControllerCollection
(exports ? this).CoffeeMVC = new CoffeeMVC()
