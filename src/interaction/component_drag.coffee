$ = require('jquery')
dom = require('./dom')
isSupported = require('../modules/feature_detection/is_supported')
config = require('../configuration/config')
css = config.css

module.exports = class ComponentDrag

  wiggleSpace = 0
  startAndEndOffset = 0

  constructor: ({ @componentModel, componentView }) ->
    @$view = componentView.$html if componentView
    @$highlightedContainer = {}


  # Called by DragBase
  start: (eventPosition) ->
    @started = true
    @page.editableController.disableAll()
    @page.blurFocusedElement()

    # placeholder below cursor
    @$placeholder = @createPlaceholder().css('pointer-events': 'none')
    @$dragBlocker = @page.$body.find(".#{ css.dragBlocker }")

    # drop marker
    @$dropMarker = $("<div class='#{ css.dropMarker }'>")

    @page.$body
      .append(@$dropMarker)
      .append(@$placeholder)
      .css('cursor', 'pointer')

    # mark dragged component
    @$view.addClass(css.dragged) if @$view?

    # position the placeholder
    @move(eventPosition)


  # Called by DragBase

  move: (eventPosition) ->
    @$placeholder.css
      left: "#{ eventPosition.pageX }px"
      top: "#{ eventPosition.pageY }px"

    @target = @findDropTarget(eventPosition)
    # @scrollIntoView(top, event)


  findDropTarget: (eventPosition) ->
    { eventPosition, elem } = @getElemUnderCursor(eventPosition)
    return undefined unless elem?

    # return the same as last time if the cursor is above the dropMarker
    return @target if elem == @$dropMarker[0]

    coords = { left: eventPosition.pageX, top: eventPosition.pageY }
    target = dom.dropTarget(elem, coords) if elem?
    target = undefined if not @canBeDropped(target)
    @undoMakeSpace()

    if target? && target.componentView?.model != @componentModel
      @$placeholder.removeClass(css.noDrop)
      @markDropPosition(target)

      # if target.containerName
      #   dom.maximizeContainerHeight(target.parent)
      #   $container = $(target.node)
      # else if target.componentView
      #   dom.maximizeContainerHeight(target.componentView)
      #   $container = target.componentView.get$container()

      return target
    else
      @$dropMarker.hide()
      @removeContainerHighlight()

      if not target?
        @$placeholder.addClass(css.noDrop)
      else
        @$placeholder.removeClass(css.noDrop)

      return undefined


  # Check if the component is allowed to be dropped
  # at the specified target.
  canBeDropped: (target) ->
    return false unless target?

    componentTree = target.componentTree
    componentTree ?= target.componentView.model.componentTree
    isAllowed = componentTree.isDropAllowed(@componentModel, target)
    return isAllowed


  markDropPosition: (target) ->
    switch target.target
      when 'component'
        @componentPosition(target)
        @removeContainerHighlight()
      when 'container'
        @showMarkerAtBeginningOfContainer(target.node)
        @highlighContainer($(target.node))
      when 'root'
        @showMarkerAtBeginningOfContainer(target.node)
        @highlighContainer($(target.node))


  componentPosition: (target) ->
    if target.position == 'before'
      before = target.componentView.prev()

      if before?
        if before.model == @componentModel
          target.position = 'after'
          return @componentPosition(target)

        @showMarkerBetweenComponents(before, target.componentView)
      else
        @showMarkerAtBeginningOfContainer(target.componentView.$elem[0].parentNode)
    else
      next = target.componentView.next()
      if next?
        if next.model == @componentModel
          target.position = 'before'
          return @componentPosition(target)

        @showMarkerBetweenComponents(target.componentView, next)
      else
        @showMarkerAtEndOfContainer(target.componentView.$elem[0].parentNode)


  showMarkerBetweenComponents: (viewA, viewB) ->
    boxA = dom.getAbsoluteBoundingClientRect(viewA.$elem[0])
    boxB = dom.getAbsoluteBoundingClientRect(viewB.$elem[0])

    halfGap = if boxB.top > boxA.bottom
      (boxB.top - boxA.bottom) / 2
    else
      0

    @showMarker
      left: boxA.left
      top: boxA.bottom + halfGap
      width: boxA.width


  showMarkerAtBeginningOfContainer: (elem) ->
    return unless elem?

    @makeSpace(elem.firstChild, 'top')
    box = dom.getAbsoluteBoundingClientRect(elem)
    paddingTop = parseInt($(elem).css('padding-top')) || 0
    @showMarker
      left: box.left
      top: box.top + startAndEndOffset + paddingTop
      width: box.width


  showMarkerAtEndOfContainer: (elem) ->
    return unless elem?

    @makeSpace(elem.lastChild, 'bottom')
    box = dom.getAbsoluteBoundingClientRect(elem)
    paddingBottom = parseInt($(elem).css('padding-bottom')) || 0
    @showMarker
      left: box.left
      top: box.bottom - startAndEndOffset - paddingBottom
      width: box.width


  showMarker: ({ left, top, width }) ->
    if @iframeBox?
      # translate to relative to iframe viewport
      $body = $(@iframeBox.window.document.body)
      top -= $body.scrollTop()
      left -= $body.scrollLeft()

      # translate to relative to viewport (fixed positioning)
      left += @iframeBox.left
      top += @iframeBox.top

      # translate to relative to document (absolute positioning)
      # top += $(document.body).scrollTop()
      # left += $(document.body).scrollLeft()

      # With position fixed we don't need to take scrolling into account
      # in an iframe scenario
      @$dropMarker.css(position: 'fixed')
    else
      # If we're not in an iframe left and top are already
      # the absolute coordinates
      @$dropMarker.css(position: 'absolute')

    @$dropMarker
    .css
      left:  "#{ left }px"
      top:   "#{ top }px"
      width: "#{ width }px"
    .show()


  makeSpace: (node, position) ->
    return unless wiggleSpace && node?
    $node = $(node)
    @lastTransform = $node

    if position == 'top'
      $node.css(transform: "translate(0, #{ wiggleSpace }px)")
    else
      $node.css(transform: "translate(0, -#{ wiggleSpace }px)")


  undoMakeSpace: (node) ->
    if @lastTransform?
      @lastTransform.css(transform: '')
      @lastTransform = undefined


  highlighContainer: ($container) ->
    if $container[0] != @$highlightedContainer[0]
      @$highlightedContainer.removeClass?(css.containerHighlight)
      @$highlightedContainer = $container
      @$highlightedContainer.addClass?(css.containerHighlight)


  removeContainerHighlight: ->
    @$highlightedContainer.removeClass?(css.containerHighlight)
    @$highlightedContainer = {}


  # pageX, pageY: absolute positions (relative to the document)
  # clientX, clientY: fixed positions (relative to the viewport)
  getElemUnderCursor: (eventPosition) ->
    elem = undefined
    @unblockElementFromPoint =>
      { clientX, clientY } = eventPosition

      if clientX? && clientY?
        elem = @page.document.elementFromPoint(clientX, clientY)

      if elem?.nodeName == 'IFRAME'
        { eventPosition, elem } = @findElemInIframe(elem, eventPosition)
      else
        @iframeBox = undefined

    { eventPosition, elem }


  findElemInIframe: (iframeElem, eventPosition) ->
    @iframeBox = box = iframeElem.getBoundingClientRect()
    @iframeBox.window = iframeElem.contentWindow
    document = iframeElem.contentDocument
    $body = $(document.body)

    eventPosition.clientX -= box.left
    eventPosition.clientY -= box.top
    eventPosition.pageX = eventPosition.clientX + $body.scrollLeft()
    eventPosition.pageY = eventPosition.clientY + $body.scrollTop()
    elem = document.elementFromPoint(eventPosition.clientX, eventPosition.clientY)

    { eventPosition, elem }


  # Remove elements under the cursor which could interfere
  # with document.elementFromPoint()
  unblockElementFromPoint: (callback) ->

    # Pointer Events are a lot faster since the browser does not need
    # to repaint the whole screen. IE 9 and 10 do not support them.
    if isSupported('htmlPointerEvents')
      @$dragBlocker.css('pointer-events': 'none')
      callback()
      @$dragBlocker.css('pointer-events': 'auto')
    else
      @$dragBlocker.hide()
      @$placeholder.hide()
      callback()
      @$dragBlocker.show()
      @$placeholder.show()


  # Called by DragBase
  drop: ->
    if @target?
      @moveToTarget(@target)
      @page.componentWasDropped.fire(@componentModel)
    else
      #consider: maybe add a 'drop failed' effect


  # Move the component after a successful drop
  moveToTarget: (target) ->
    switch target.target
      when 'component'
        componentView = target.componentView
        if target.position == 'before'
          componentView.model.before(@componentModel)
        else
          componentView.model.after(@componentModel)
      when 'container'
        componentModel = target.componentView.model
        componentModel.append(target.containerName, @componentModel)
      when 'root'
        componentTree = target.componentTree
        componentTree.prepend(@componentModel)



  # Called by DragBase
  # Reset is always called after a drag ended.
  reset: ->
    if @started

      # undo DOM changes
      @undoMakeSpace()
      @removeContainerHighlight()
      @page.$body.css('cursor', '')
      @page.editableController.reenableAll()
      @$view.removeClass(css.dragged) if @$view?
      dom.restoreContainerHeight()

      # remove elements
      @$placeholder.remove()
      @$dropMarker.remove()


  createPlaceholder: ->
    numberOfDraggedElems = 1
    template = """
      <div class="#{ css.draggedPlaceholder }">
        <span class="#{ css.draggedPlaceholderCounter }">
          #{ numberOfDraggedElems }
        </span>
        Selected Item
      </div>
      """

    $placeholder = $(template)
      .css(position: "absolute")
