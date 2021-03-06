$ = require('jquery')
deepEqual = require('deep-equal')
config = require('../configuration/config')
guid = require('../modules/guid')
log = require('../modules/logging/log')
assert = require('../modules/logging/assert')
ComponentModel = require('./component_model')
serialization = require('../modules/serialization')

module.exports = do ->

  # Public Methods
  # --------------

  # Serialize a ComponentModel
  #
  # Extends the prototype of ComponentModel
  #
  # Example Result:
  # id: 'akk7hjuue2'
  # identifier: 'timeline.title'
  # content: { ... }
  # styles: { ... }
  # data: { ... }
  # containers: { ... }
  ComponentModel::toJson = (component) ->
    component ?= this

    json =
      id: component.id
      identifier: component.template.identifier

    unless serialization.isEmpty(component.content)
      json.content = serialization.flatCopy(component.content)

    unless serialization.isEmpty(component.styles)
      json.styles = serialization.flatCopy(component.styles)

    unless serialization.isEmpty(component.dataValues)
      json.data = $.extend(true, {}, component.dataValues)

    unless serialization.isEmpty(component.dataInlineStyles)
      json.inlineStylesData = $.extend(true, {}, component.dataInlineStyles)

    unless serialization.isEmpty(component.inlineStyles)
      json.inlineStyles = $.extend(true, {}, component.inlineStyles)

    # create an array for every container
    for name of component.containers
      json.containers ||= {}
      json.containers[name] = []

    json


  fromJson: (json, design) ->
    template = design.get(json.component || json.identifier)

    assert template,
      "error while deserializing component: unknown template identifier '#{ json.identifier }'"

    model = new ComponentModel({ template, id: json.id })

    for name, value of json.content
      assert model.content.hasOwnProperty(name),
        "error while deserializing component #{ model.componentName }: unknown content '#{ name }'"

      # Transform string into object: Backwards compatibility for old image values.
      if model.directives.get(name).type == 'image' && typeof value == 'string'
        model.content[name] =
          url: value
      else
        model.content[name] = value

    for styleName, value of json.styles
      model.setStyle(styleName, value)

    model.data(json.data) if json.data

    model.inlineData(json.inlineStylesData) if json.inlineStylesData

    model.setInlineStyles(json.inlineStyles) if json.inlineStyles

    for containerName, componentArray of json.containers
      assert model.containers.hasOwnProperty(containerName),
        "error while deserializing component: unknown container #{ containerName }"

      if componentArray
        assert $.isArray(componentArray),
          "error while deserializing component: container is not array #{ containerName }"
        for child in componentArray
          model.append( containerName, @fromJson(child, design) )

    model

