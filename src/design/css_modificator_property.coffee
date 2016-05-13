log = require('../modules/logging/log')
assert = require('../modules/logging/assert')
words = require('../modules/words')

module.exports = class CssModificatorProperty

  constructor: ({ @name, label, @type, value, options,  @pattern,  @defaultValue, @unit, @cssProp, @inputPlaceholder}) ->
    @label = label || words.humanize( @name )

    switch @type
      when 'option'
        assert value, "TemplateStyle error: no 'value' provided"
        @value = value
      when 'select'
        assert options, "TemplateStyle error: no 'options' provided"
        @options = options
      when 'text'
        @value = value
      else
        log.error "TemplateStyle error: unknown type '#{ @type }'"


  # Get instructions which css classes to add and remove.
  # We do not control the class attribute of a component DOM element
  # since the UI or other scripts can mess with it any time. So the
  # instructions are designed not to interfere with other css classes
  # present in an elements class attribute.
  cssClassChanges: (value) ->
    if @validateValue(value)
      if @type is 'option'
        remove: if not value then [@value] else undefined
        add: value
      else if @type is 'select'
        remove: @otherClasses(value)
        add: value
    else
      if @type is 'option'
        remove: currentValue
        add: undefined
      else if @type is 'select'
        remove: @otherClasses(undefined)
        add: undefined


  validateValue: (value) ->
    if not value
      true
    else if @type is 'option'
      value == @value
    else if @type is 'select'
      @containsOption(value)
    else if @type is 'text'
      true
    else
      log.warn "Not implemented: CssModificatorProperty#validateValue() for type #{ @type }"


  containsOption: (value) ->
    for option in @options
      return true if value is option.value

    false


  otherOptions: (value) ->
    others = []
    for option in @options
      others.push option if option.value isnt value

    others


  otherClasses: (value) ->
    others = []
    for option in @options
      others.push option.value if option.value isnt value

    others
