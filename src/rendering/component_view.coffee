$ = require('jquery')
_ = require('underscore')
config = require('../configuration/config')
css = config.css
attr = config.attr
DirectiveIterator = require('../template/directive_iterator')
eventing = require('../modules/eventing')
dom = require('../interaction/dom')

module.exports = class ComponentView

  constructor: ({ @model, @$html, @directives, @isReadOnly, @forceHtmlSet }) ->
    @renderer = undefined # will be set once the view is attached to a renderer
    @$elem = @$html
    @template = @model.template
    @isAttachedToDom = false
    @wasAttachedToDom = $.Callbacks();
    @rootComponentKey = 'root'

    @decorateMarkup()
    @render()


  decorateMarkup: ->
    unless @isReadOnly
      # add attributes and references to the html
      @$html
        .data('componentView', this)
        .addClass(css.component)
        .attr(attr.template, @template.identifier)


  # Renderer
  # --------

  setRenderer: (renderer) ->
    @renderer = renderer


  removeRenderer: ->
    @renderer = undefined


  viewForModel: (model) ->
    @renderer?.getComponentViewById(model.id) if model?


  recreateHtml: ->
    @isAttachedToDom = false
    { @$elem, @directives } = @model.template.createViewHtml(@model)
    @$html = @$elem

    @decorateMarkup()
    @render()


  # Remove, recreate and reinsert the html of this view.
  refresh: ->
    @renderer.refreshComponent(@model)


  render: (mode) ->
    @updateContent()
    @updateData()
    @updateInlineStylesData()
    @updateHtml()


  updateContent: (directiveName) ->
    if directiveName
      @set(directiveName, @model.content[directiveName])
    else
      @setAll()

    if not @hasFocus()
      @displayOptionals()

    @stripHtmlIfReadOnly()


  updateHtml: ->
    for name, value of @model.styles
      @setStyle(name, value)

    for name, value of @model.content
      @setInlineStyle(name)
    for name, value of @model.containers
      @setInlineStyle(name)
    # sets the style on the root element
    @setInlineStyle()

    @stripHtmlIfReadOnly()


  updateData: () ->
    # Hyperlink data type alters the html structure
    hyperlink = @model.dataValues['hyperlink']
    if hyperlink
      @setHyperlink(hyperlink)
      @stripHtmlIfReadOnly()
    return


  updateInlineStylesData: () ->
  # Set inline styles
    for property, value of @model.dataInlineStyles
      @setCssStyle(@, @model.template.styles[property]['cssProp'], value, @model.template.styles[property]['defaultValue'], @model.template.styles[property]['unit'])
    return

  setCssStyle: (elem, property, value, defaultValue, unit) ->
    if value isnt defaultValue
      elem.$html.css property, value+unit
    else
      elem.$html.css property, ''

  displayOptionals: ->
    @directives.each (directive) =>
      if directive.optional
        $elem = $(directive.elem)
        if @model.isEmpty(directive.name)
          $elem.css('display', 'none')
        else
          $elem.css('display', '')


  # Show all doc-optionals whether they are empty or not.
  # Use on focus.
  showOptionals: ->
    @directives.each (directive) =>
      if directive.optional
        config.animations.optionals.show($(directive.elem))


  # Hide all empty doc-optionals
  # Use on blur.
  hideEmptyOptionals: ->
    @directives.each (directive) =>
      if directive.optional && @model.isEmpty(directive.name)
        config.animations.optionals.hide($(directive.elem))


  # Focus
  # -----

  afterFocused: () ->
    @$html.addClass(css.componentHighlight)
    @showOptionals()


  afterBlurred: () ->
    @$html.removeClass(css.componentHighlight)
    @hideEmptyOptionals()


  # @param cursor: undefined, 'start', 'end'
  focus: (editableName) ->
    directive = if editableName
      @directives.get(editableName)
    else
      @directives.editable?[0]

    $(directive?.elem).focus()

  hasFocus: ->
    @$html.hasClass(css.componentHighlight)


  getBoundingClientRect: ->
    @$html[0].getBoundingClientRect()


  getAbsoluteBoundingClientRect: ->
    dom.getAbsoluteBoundingClientRect(@$html[0])


  # Set all directives at once
  setAll: ->
    for name, value of @model.content
      @set(name, value)

    undefined


  # Set the style on passed directive element
  #
  # @param {!string} name The name of the directive
  # in which the inline style will be applied
  setInlineStyle: (name) ->
    items = if name then @_findInlineElementAndStyles name else @_findInlineElementAndStyles @rootComponentKey, @$html
    for item in items
      $elem = item[0]
      value = item[1]
      if $elem
        # remove previous styles first
        @_removeLastInlineStyles $elem
        if value
          # set styles
          $elem.css value
          # store styles
          @_storeInlineStyles $elem, value;


  _findInlineElementAndStyles: (name, $elem) ->
    result = []
    value = @model.inlineStyles[name]
    $elem ||= @directives.$getElem name
    if _.isArray value
      for item in value
        $itemElem = item.elem && $elem.find(item.elem) || $elem
        itemValue = item.value
        result.push [$itemElem, itemValue]
    else
      result.push [$elem, value]

    result


  # Remove previous styles
  #
  # @param el jquery Element
  _removeLastInlineStyles: (el) ->
    if (el.data('lastInlineStyles'))
      for k, v of el.data('lastInlineStyles')
        el.css(k, '');


  # Store inline styles
  _storeInlineStyles: (el, styles) ->
    el.data('lastInlineStyles', $.extend({}, styles));


  set: (name, value) ->
    directive = @model.directives.get(name)
    switch directive.type
      when 'editable' then @setEditable(name, value)
      when 'image'
        if directive.base64Image?
          @setImage(name, directive.base64Image)
        else
          @setImage(name, directive.getImageUrl() )

      when 'html' then @setHtml(name, value)
      when 'link' then @setLink(name, value)


  get: (name) ->
    directive = @directives.get(name)
    switch directive.type
      when 'editable' then @getEditable(name)
      when 'image' then @getImage(name)
      when 'html' then @getHtml(name)
      when 'link' then @getLink(name)


  getEditable: (name) ->
    $elem = @directives.$getElem(name)
    $elem.html()


  setEditable: (name, value) ->
    $elem = @directives.$getElem(name)

    # Check if the directive element has focus to avoid
    # circular code execution.
    element = $elem[0]
    ownerDocument = element.ownerDocument
    elementHasFocus = ownerDocument.activeElement == element

    return if elementHasFocus

    $elem.toggleClass(css.noPlaceholder, Boolean(value))
    $elem.attr(attr.placeholder, @template.defaults[name])
    $elem.html(value || '')


  focusEditable: (name) ->
    $elem = @directives.$getElem(name)
    $elem.addClass(css.noPlaceholder)


  blurEditable: (name) ->
    $elem = @directives.$getElem(name)
    if @model.isEmpty(name)
      $elem.removeClass(css.noPlaceholder)


  getHtml: (name) ->
    $elem = @directives.$getElem(name)
    $elem.html()


  setHtml: (name, value) ->
    $elem = @directives.$getElem(name)
    # to prevent any error in current work frame set html in the next one
    if value
      if @forceHtmlSet
        @_setHtml($elem, value);
      else
        @setHtmlInNewWorkFrame($elem, value)

    if not value
      $elem.html(@template.defaults[name])
    else if value and not @isReadOnly and config.shouldBlockInteraction
      @blockInteraction($elem)

    @directivesToReset ||= {}
    @directivesToReset[name] = name
    
    
  setHtmlInNewWorkFrame: ($elem, value) ->
    $self = this
    window.setTimeout ( ->
      if $elem
        $self._setHtml($elem, value)
    ), 0


  _setHtml: ($elem, value) ->
    $elem.get(0).innerHTML = value;
    # do some magic here with scripts - replace them to make it work in iframes
    $elem.find('script').replaceWith( ->
      script = $elem.get(0).ownerDocument.createElement('script');
      if @.getAttribute('src')
        script.setAttribute('src', @.getAttribute('src'));
      else
        script.innerHTML = @.innerHTML;
      @.parentNode.insertBefore(script, @.nextSibling)
      return '';
    )


  setLink: (name, value) ->
    $elem = @directives.$getElem(name)
    if value
      $elem.attr('href', value)
    else
      # According to HTML5 we remove the href attribute to
      # create a placeholder link that is not clickable.
      $elem.removeAttr('href')


  getLink: (name) ->
    $elem = @directives.$getElem(name)
    $elem.attr('href')


  getDirectiveElement: (directiveName) ->
    @directives.get(directiveName)?.elem


  # Reset directives that contain arbitrary html after the view is moved in
  # the DOM to recreate iframes. In the case of twitter where the iframes
  # don't have a src the reloading that happens when one moves an iframe clears
  # all content (Maybe we could limit resetting to iframes without a src).
  #
  # Some more info about the issue on stackoverflow:
  # http://stackoverflow.com/questions/8318264/how-to-move-an-iframe-in-the-dom-without-losing-its-state
  resetDirectives: ->
    for name of @directivesToReset
      $elem = @directives.$getElem(name)
      if $elem.find('iframe').length
        @set(name, @model.content[name])


  getImage: (name) ->
    $elem = @directives.$getElem(name)
    $elem.attr('src')


  setImage: (name, value) ->
    $elem = @directives.$getElem(name)

    if value
      @cancelDelayed(name)

      imageService = @model.directives.get(name).getImageService()
      imageService.set($elem, value)

      $elem.removeClass(config.css.emptyImage)
    else
      setPlaceholder = $.proxy(@setPlaceholderImage, this, $elem, name)
      @delayUntilAttached(name, setPlaceholder) # todo: replace with @afterInserted -> ... (something like $.Callbacks('once remember'))


  setPlaceholderImage: ($elem, name) ->
    $elem.addClass(config.css.emptyImage)

    imageService = @model.directives.get(name).getImageService()
    imageService.set($elem, config.imagePlaceholder)


  setStyle: (name, className) ->
    changes = @template.styles[name].cssClassChanges(className)
    if changes.remove
      for removeClass in changes.remove
        @$html.removeClass(removeClass)

    @$html.addClass(changes.add)

  setHyperlink: (value) ->
    $elem = @directives.$getElem(@model.componentName)
    $elem.attr("data-hyperlink",  value || undefined )
    if @isReadOnly
      if value
        $elem.find('a').attr('href', value).length or $elem.append($('<a>', href: value))
      else
        $elem.find('a').remove()


  # Disable tabbing for the children of an element.
  # This is used for html content so it does not disrupt the user
  # experience. The timeout is used for cases like tweets where the
  # iframe is generated by a script with a delay.
  disableTabbing: ($elem) ->
    setTimeout( =>
      $elem.find('iframe').attr('tabindex', '-1')
    , 400)


  # Append a child to the element which will block user interaction
  # like click or touch events. Also try to prevent the user from getting
  # focus on a child elemnt through tabbing.
  blockInteraction: ($elem) ->
    @ensureRelativePosition($elem)
    $blocker = $("<div class='#{ css.interactionBlocker }'>")
      .attr('style', 'position: absolute; top: 0; bottom: 0; left: 0; right: 0;')
    $elem.append($blocker)

    @disableTabbing($elem)


  # Make sure that all absolute positioned children are positioned
  # relative to $elem.
  ensureRelativePosition: ($elem) ->
    position = $elem.css('position')
    if position != 'absolute' && position != 'fixed' && position != 'relative'
      $elem.css('position', 'relative')


  get$container: ->
    $(dom.findContainer(@$html[0]).node)


  # Wait to execute a method until the view is attached to the DOM
  delayUntilAttached: (name, func) ->
    if @isAttachedToDom
      func()
    else
      @cancelDelayed(name)
      @delayed ||= {}
      @delayed[name] = eventing.callOnce @wasAttachedToDom, =>
        @delayed[name] = undefined
        func()


  cancelDelayed: (name) ->
    if @delayed?[name]
      @wasAttachedToDom.remove(@delayed[name])
      @delayed[name] = undefined


  stripHtmlIfReadOnly: ->
    return unless @isReadOnly

    iterator = new DirectiveIterator(@$html[0])
    while elem = iterator.nextElement()
      @stripDocClasses(elem)
      @stripDocAttributes(elem)
      @stripEmptyAttributes(elem)


  stripDocClasses: (elem) ->
    $elem = $(elem)
    for klass in elem.className.split(/\s+/)
      $elem.removeClass(klass) if /doc\-.*/i.test(klass)


  stripDocAttributes: (elem) ->
    $elem = $(elem)
    for attribute in Array::slice.apply(elem.attributes)
      name = attribute.name
      $elem.removeAttr(name) if /data\-doc\-.*/i.test(name)


  stripEmptyAttributes: (elem) ->
    $elem = $(elem)
    strippableAttributes = ['style', 'class']
    for attribute in Array::slice.apply(elem.attributes)
      isStrippableAttribute = strippableAttributes.indexOf(attribute.name) >= 0
      isEmptyAttribute = attribute.value.trim() == ''
      if isStrippableAttribute and isEmptyAttribute
        $elem.removeAttr(attribute.name)


  setAttachedToDom: (newVal) ->
    return if newVal == @isAttachedToDom

    @isAttachedToDom = newVal

    if newVal
      @resetDirectives()
      @wasAttachedToDom.fire()


  getOwnerWindow: ->
    @$elem[0].ownerDocument.defaultView


  # Iterators and Tree accessors
  # ----------------------------
  #
  # See the end of this file for the generated iterators
  # ('children', 'descendants', 'parents' etc.).

  next: ->
    @viewForModel(@model.next)


  prev: -> @previous() # alias
  previous: ->
    @viewForModel(@model.previous)


  parent: ->
    @viewForModel(@model.getParent())


# Generate componentView Iterators
# --------------------------------

['parents', 'children', 'childrenAndSelf', 'descendants', 'descendantsAndSelf'].forEach (method) ->
  ComponentView::[method] = (callback) ->
    @model[method] (model) =>
      callback( @viewForModel(model) )

