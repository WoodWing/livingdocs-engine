d3 = require('d3')
!do ->
  Donut3D = {}

  pieTop = (d, rx, ry, ir) ->
    if d.endAngle - (d.startAngle) == 0
      return 'M 0 0'
    sx = rx * Math.cos(d.startAngle)
    sy = ry * Math.sin(d.startAngle)
    ex = rx * Math.cos(d.endAngle)
    ey = ry * Math.sin(d.endAngle)
    ret = []
    ret.push("M",sx,sy,"A",rx,ry,"0",(d.endAngle-d.startAngle > Math.PI? 1: 0),"1",ex,ey,"L",ir*ex,ir*ey);
    ret.push("A",ir*rx,ir*ry,"0",(d.endAngle-d.startAngle > Math.PI? 1: 0), "0",ir*sx,ir*sy,"z");
    ret.join ' '

  pieOuter = (d, rx, ry, h) ->
    startAngle = if d.startAngle > Math.PI then Math.PI else d.startAngle
    endAngle = if d.endAngle > Math.PI then Math.PI else d.endAngle
    sx = rx * Math.cos(startAngle)
    sy = ry * Math.sin(startAngle)
    ex = rx * Math.cos(endAngle)
    ey = ry * Math.sin(endAngle)
    ret = []
    ret.push 'M', sx, h + sy, 'A', rx, ry, '0 0 1', ex, h + ey, 'L', ex, ey, 'A', rx, ry, '0 0 0', sx, sy, 'z'
    ret.join ' '

  pieInner = (d, rx, ry, h, ir) ->
    startAngle = if d.startAngle < Math.PI then Math.PI else d.startAngle
    endAngle = if d.endAngle < Math.PI then Math.PI else d.endAngle
    sx = ir * rx * Math.cos(startAngle)
    sy = ir * ry * Math.sin(startAngle)
    ex = ir * rx * Math.cos(endAngle)
    ey = ir * ry * Math.sin(endAngle)
    ret = []
    ret.push 'M', sx, sy, 'A', ir * rx, ir * ry, '0 0 1', ex, ey, 'L', ex, h + ey, 'A', ir * rx, ir * ry, '0 0 0', sx, h + sy, 'z'
    ret.join ' '

  getPercent = (d) ->
    if d.endAngle - (d.startAngle) > 0.2 then Math.round(1000 * (d.endAngle - (d.startAngle)) / (Math.PI * 2)) / 10 + '%' else ''

  Donut3D.transition = (id, data, rx, ry, h, ir) ->
    _data = d3.layout.pie().sort(null).value((d) ->
      d.value
    )(data)

    arcTweenInner = (a) ->
      i = d3.interpolate(@_current, a)
      @_current = i(0)
      (t) ->
        pieInner i(t), rx + 0.5, ry + 0.5, h, ir

    arcTweenTop = (a) ->
      i = d3.interpolate(@_current, a)
      @_current = i(0)
      (t) ->
        pieTop i(t), rx, ry, ir

    arcTweenOuter = (a) ->
      i = d3.interpolate(@_current, a)
      @_current = i(0)
      (t) ->
        pieOuter i(t), rx - .5, ry - .5, h

    textTweenX = (a) ->
      i = d3.interpolate(@_current, a)
      @_current = i(0)
      (t) ->
        0.6 * rx * Math.cos(0.5 * (i(t).startAngle + i(t).endAngle))

    textTweenY = (a) ->
      i = d3.interpolate(@_current, a)
      @_current = i(0)
      (t) ->
        0.6 * rx * Math.sin(0.5 * (i(t).startAngle + i(t).endAngle))

    d3.select('#' + id).selectAll('.innerSlice').data(_data).transition().duration(750).attrTween 'd', arcTweenInner
    d3.select('#' + id).selectAll('.topSlice').data(_data).transition().duration(750).attrTween 'd', arcTweenTop
    d3.select('#' + id).selectAll('.outerSlice').data(_data).transition().duration(750).attrTween 'd', arcTweenOuter
    d3.select('#' + id).selectAll('.percent').data(_data).transition().duration(750).attrTween('x', textTweenX).attrTween('y', textTweenY).text getPercent
    return

  Donut3D.draw = (id, data, x, y, rx, ry, h, ir) ->
    _data = d3.layout.pie().sort(null).value((d) ->
      d.value
    )(data)
    slices = d3.select('#' + id).append('g').attr('transform', 'translate(' + x + ',' + y + ')').attr('class', 'slices')
    slices.selectAll('.innerSlice').data(_data).enter().append('path').attr('class', 'innerSlice').style('fill', (d) ->
      d3.hsl(d.data.color).darker 0.7
    ).attr('d', (d) ->
      pieInner d, rx + 0.5, ry + 0.5, h, ir
    ).each (d) ->
      @_current = d
      return
    slices.selectAll('.topSlice').data(_data).enter().append('path').attr('class', 'topSlice').style('fill', (d) ->
      d.data.color
    ).style('stroke', (d) ->
      d.data.color
    ).attr('d', (d) ->
      pieTop d, rx, ry, ir
    ).each (d) ->
      @_current = d
      return
    slices.selectAll('.outerSlice').data(_data).enter().append('path').attr('class', 'outerSlice').style('fill', (d) ->
      d3.hsl(d.data.color).darker 0.7
    ).attr('d', (d) ->
      pieOuter d, rx - .5, ry - .5, h
    ).each (d) ->
      @_current = d
      return
    slices.selectAll('.percent').data(_data).enter().append('text').attr('class', 'percent').attr('x', (d) ->
      0.6 * rx * Math.cos(0.5 * (d.startAngle + d.endAngle))
    ).attr('y', (d) ->
      0.6 * ry * Math.sin(0.5 * (d.startAngle + d.endAngle))
    ).text(getPercent).each (d) ->
      @_current = d
      return
    return

  @Donut3D = Donut3D
  return