assert = require('../modules/logging/assert')
imageService = require('../image_services/image_service')

EditableDirective = require('./editable_directive')
ImageDirective = require('./image_directive')
HtmlDirective = require('./html_directive')
LinkDirective = require('./link_directive')
ChartDirective = require('./chart_directive')

module.exports =

  create: ({ component, templateDirective }) ->
    Directive = @getDirectiveConstructor(templateDirective.type)
    new Directive({ component, templateDirective })


  getDirectiveConstructor: (directiveType) ->
    switch directiveType
      when 'editable'
        EditableDirective
      when 'image'
        ImageDirective
      when 'html'
        HtmlDirective
      when 'link'
        LinkDirective
      when 'chart'
        ChartDirective
      else
        assert false, "Unsupported component directive: #{ directiveType }"
