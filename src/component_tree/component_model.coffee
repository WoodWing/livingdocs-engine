deepEqual = require('deep-equal')
config = require('../configuration/config')
ComponentContainer = require('./component_container')
guid = require('../modules/guid')
log = require('../modules/logging/log')
assert = require('../modules/logging/assert')
directiveFactory = require('./component_directive_factory')
DirectiveCollection = require('../template/directive_collection')

# ComponentModel
# ------------
# Each ComponentModel has a template which allows to generate a componentView
# from a componentModel
#
# Represents a node in a ComponentTree.
# Every ComponentModel can have a parent (ComponentContainer),
# siblings (other components) and multiple containers (ComponentContainers).
#
# The containers are the parents of the child ComponentModels.
# E.g. a grid row would have as many containers as it has
# columns
#
# # @prop parentContainer: parent ComponentContainer
module.exports = class ComponentModel

  constructor: ({ @template, id } = {}) ->
    assert @template, 'cannot instantiate component without template reference'

    @initializeDirectives()
    @styles = {}
    @dataValues = {}
    @dataInlineStyles = {}
    @id = id || guid.next()
    @componentName = @template.name

    @next = undefined # set by ComponentContainer
    @previous = undefined # set by ComponentContainer
    @componentTree = undefined # set by ComponentTree
    @inlineStyles ||= {}


  initializeDirectives: ->
    @directives = new DirectiveCollection()

    for directive in @template.directives
      switch directive.type
        when 'container'
          @containers ||= {}
          @containers[directive.name] = new ComponentContainer
            name: directive.name
            parentComponent: this
            config: directive.config
        when 'editable', 'image', 'html', 'link'
          @createComponentDirective(directive)
          @content ||= {}
          @content[directive.name] = undefined
        else
          log.error "Template directive type '#{ directive.type }' not implemented in ComponentModel"


  # Create a directive for 'editable', 'image', 'html' template directives
  createComponentDirective: (templateDirective) ->
    @directives.add directiveFactory.create
      component: this
      templateDirective: templateDirective


  # View operations
  # ---------------


  createView: (isReadOnly, forceHtmlSet) ->
    @template.createView(this, isReadOnly, forceHtmlSet)


  getMainView: ->
    @componentTree.getMainComponentView(this.id)


  # ComponentTree operations
  # ------------------------

  # @param {ComponentModel}
  isAllowedAsSibling: (component) ->
    @parentContainer.isAllowedAsChild(component)


  # @param {Template}
  isTypeAllowedAsSibling: (template) ->
    return true unless @parentContainer?
    @parentContainer.isTypeAllowedAsChild(template)


  isAllowedAsChild: (containerName, component) ->
    @containers[containerName].isAllowedAsChild(component)


  # Insert a component before this one
  before: (componentModel) ->
    if componentModel
      @parentContainer.insertBefore(this, componentModel)
      this
    else
      @previous


  # Insert a component after this one
  after: (componentModel) ->
    if componentModel
      @parentContainer.insertAfter(this, componentModel)
      this
    else
      @next


  # Append a component to a container of this component
  append: (containerName, componentModel) ->
    @containers[containerName].append(componentModel)
    this


  # Prepend a component to a container of this component
  prepend: (containerName, componentModel) ->
    @containers[containerName].prepend(componentModel)
    this


  # Move this component up (previous)
  up: ->
    @parentContainer.up(this)
    this


  # Move this component down (next)
  down: ->
    @parentContainer.down(this)
    this


  # Remove this component from its container and ComponentTree
  remove: ->
    @parentContainer.remove(this)


  # Transform operations
  # --------------------

  getTransforms: ->
    transforms = @template.design?.transforms


  # @return {Array of { label, componentName }} Array of component names
  getTransformOptions: ({ oneWay, directives }={}) ->
    transforms = @getTransforms()
    return unless transforms?

    transforms.getOptionsList
      template: @template
      oneWay: oneWay
      directives: directives
      filter: (template) =>
        @isTypeAllowedAsSibling(template)


  # Change this component into another component.
  # Check for available options with getTransformOptions().
  #
  # This method will throw an error if an invalid componentName
  # is supplied.
  #
  # @param {String} componentName
  # @returns {ComponentModel} The new componentModel in this spot
  transform: (componentName) ->
    transforms = @getTransforms()
    design = @template.design
    newTemplate = design.get(componentName)

    compatibility = transforms.isCompatible(this, newTemplate, oneWay: true)
    assert compatibility.isCompatible, "Component #{ @componentName } can not be transformed into #{ componentName }."

    newModel = newTemplate.createModel()
    for from, to of compatibility.mapping || []
      fromDirective = @directives.get(from)
      newDirective = newModel.directives.get(to)
      fromDirective.copyTo(newDirective)

    @replaceWith(newModel)


  # @param {ComponentModel}
  replaceWith: (otherComponent) ->
    @after(otherComponent)
    @remove()
    return otherComponent


  # ComponentTree Iterators
  # -----------------------
  #
  # Navigate and query the componentTree relative to this component.

  getParent: ->
     @parentContainer?.parentComponent


  parents: (callback) ->
    componentModel = this
    while (componentModel = componentModel.getParent())
      callback(componentModel)


  children: (callback) ->
    for name, componentContainer of @containers
      componentModel = componentContainer.first
      while (componentModel)
        callback(componentModel)
        componentModel = componentModel.next


  childrenAndSelf: (callback) ->
    callback(this)
    @children(callback)


  descendants: (callback) ->
    for name, componentContainer of @containers
      componentModel = componentContainer.first
      while (componentModel)
        callback(componentModel)
        componentModel.descendants(callback)
        componentModel = componentModel.next


  descendantsAndSelf: (callback) ->
    callback(this)
    @descendants(callback)


  # iterate over all parent containers (bubbling up)
  parentContainers: (callback) ->
    componentModel = this
    while componentModel?
      callback(componentModel.parentContainer)
      componentModel = componentModel.getParent()


  # iterate over all descendant containers (including those of this componentModel)
  descendantContainers: (callback) ->
    @descendantsAndSelf (componentModel) ->
      for name, componentContainer of componentModel.containers
        callback(componentContainer)


  # return all descendant containers and components
  allDescendants: (callback) ->
    @descendantsAndSelf (componentModel) =>
      callback(componentModel) if componentModel != this
      for name, componentContainer of componentModel.containers
        callback(componentContainer)


  # Directive Operations
  # --------------------
  #
  # Example how to get an ImageDirective:
  # imageDirective = componentModel.directives.get('image')

  hasContainers: ->
    @containers?


  hasEditables: ->
    @directives.count('editable') > 0


  hasHtml: ->
    @directives.count('html') > 0


  hasImages: ->
    @directives.count('image') > 0


  hasLinks: ->
    @directives.count('link') > 0


  # set the content data field of the component
  setContent: (name, value) ->
    if not value
      if @content[name]
        @content[name] = undefined
        @componentTree.contentChanging(this, name) if @componentTree
    else if typeof value == 'string'
      if @content[name] != value
        @content[name] = value
        @componentTree.contentChanging(this, name) if @componentTree
    else
      if not deepEqual(@content[name], value)
        @content[name] = value
        @componentTree.contentChanging(this, name) if @componentTree


  set: (name, value) ->
    assert @content?.hasOwnProperty(name),
      "set error: #{ @componentName } has no content named #{ name }"

    directive = @directives.get(name)
    if directive.isImage
      if directive.getImageUrl() != value
        directive.setImageUrl(value)
        @componentTree.contentChanging(this, name) if @componentTree
    else
      @setContent(name, value)


  get: (name) ->
    assert @content?.hasOwnProperty(name),
      "get error: #{ @componentName } has no content named #{ name }"

    @directives.get(name).getContent()


  # Check if a directive has content
  isEmpty: (name) ->
    value = @get(name)
    value == undefined || value == ''

  # set the inline style of the component
  setInlineStyles: (inlineStyles) ->
    inlineStyles ||= {}
    if (!deepEqual(@inlineStyles, inlineStyles))
      @inlineStyles = inlineStyles
      if @componentTree
        @componentTree.htmlChanging(this)

  # Data Operations
  # ---------------
  #
  # Set arbitrary data to be stored with this componentModel.


  # can be called with a string or a hash
  # getter:
  #   data() or
  #   data('my-key')
  # setter:
  #   data('my-key': 'awesome')
  data: (arg) ->
    if typeof(arg) == 'object'
      changedDataProperties = []
      for name, value of arg
        if @changeData(name, value)
          changedDataProperties.push(name)
      if changedDataProperties.length > 0
        @componentTree?.dataChanging(this, changedDataProperties)
    else if arg
      @dataValues[arg]
    else
      @dataValues


  setData: (key, value) ->
    if key && @changeData(key, value)
      @componentTree?.dataChanging(this, [key])


  getData: (key) ->
    if key
      @dataValues[key]
    else
      @dataValues


  # @api private
  changeData: (name, value) ->
    return false if deepEqual(@dataValues[name], value)

    @dataValues[name] = value
    true


  # Inline styles Data Operations
  # ---------------
  #
  # Set inline styles data to be stored with this componentModel.


  # can be called with a string or a hash
  # getter:
  #   data() or
  #   data('my-key')
  # setter:
  #   data('my-key': 'awesome')
  inlineData: (arg) ->
    if typeof(arg) == 'object'
      changedDataProperties = []
      for name, value of arg
        if @changeInlineData(name, value)
          changedDataProperties.push(name)
      if changedDataProperties.length > 0
        @componentTree?.dataChanging(this, changedDataProperties)
    else if arg
      @dataInlineStyles[arg]
    else
      @dataInlineStyles


  setInlineData: (key, value) ->
    if key && @changeInlineData(key, value)
      @componentTree?.dataChanging(this, [key])


  getInlineData: (key) ->
    if key
      @dataInlineStyles[key]
    else
      @dataInlineStyles


  # @api private
  changeInlineData: (name, value) ->
    return false if deepEqual(@dataInlineStyles[name], value)

    @dataInlineStyles[name] = value
    true


  getPluginName: ->
    @plugin?.name


  setPlugin: (plugin) ->
    @plugin = plugin


  getPlugin: (plugin) ->
    @plugin


  # Style Operations
  # ----------------

  getStyle: (name) ->
    @styles[name]


  setStyle: (name, value) ->
    style = @template.styles[name]
    if not style
      log.warn "Unknown style '#{ name }' in ComponentModel #{ @componentName }"
    else if not style.validateValue(value)
      log.warn "Invalid value '#{ value }' for style '#{ name }' in ComponentModel #{ @componentName }"
    else
      if @styles[name] != value
        @styles[name] = value
        if @componentTree
          @componentTree.htmlChanging(this, 'style', { name, value })


  # @deprecated
  # Getter and Setter in one.
  style: (name, value) ->
    console.log("ComponentModel#style() is deprecated. Please use #getStyle() and #setStyle().")
    if arguments.length == 1
      @styles[name]
    else
      @setStyle(name, value)


  # ComponentModel Operations
  # -----------------------

  copy: ->
    log.warn("ComponentModel#copy() is not implemented yet.")

    # serializing/deserializing should work but needs to get some tests first
    # json = @toJson()
    # json.id = guid.next()
    # ComponentModel.fromJson(json)


  copyWithoutContent: ->
    @template.createModel()


  # @api private
  destroy: ->
    # todo: move into to renderer

