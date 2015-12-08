d3 = require('d3')
module.exports =


  display: (dataAsString, svg) ->
    value  = JSON.parse dataAsString
    if value?.data
      data = value.data
      size = value.size
    else
      data = value
      size =
        width: 960
        height: 500
    type = value.type

    switch type
      when 'different' then @displayDifferent(data, size, svg)


  displayDifferent: (data, size, svg) ->
    margin =
      top: 20
      right: 20
      bottom: 30
      left: 50
    width = size.width - (margin.left) - (margin.right)
    height = size.height - (margin.top) - (margin.bottom)
    parseDate = d3.time.format('%Y%m%d').parse
    x = d3.time.scale().range([
      0
      width
    ])
    y = d3.scale.linear().range([
      height
      0
    ])
    xAxis = d3.svg.axis().scale(x).orient('bottom')
    yAxis = d3.svg.axis().scale(y).orient('left')
    line = d3.svg.area().interpolate('basis').x((d) ->
      x d.date
    ).y((d) ->
      y d['item1']
    )
    area = d3.svg.area().interpolate('basis').x((d) ->
      x d.date
    ).y1((d) ->
      y d['item1']
    )

    svg.attr('width', width + margin.left + margin.right).attr('height', height + margin.top + margin.bottom).append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
    data.forEach (d) ->
      d.date = parseDate(d.date)
      d['item1'] = +d['item1']
      d['item2'] = +d['item2']
      return
    x.domain d3.extent(data, (d) ->
      d.date
    )
    y.domain [
      d3.min(data, (d) ->
        Math.min d['item1'], d['item2']
      )
      d3.max(data, (d) ->
        Math.max d['item1'], d['item2']
      )
    ]
    svg.datum data
    svg.append('clipPath').attr('id', 'clip-below').append('path').attr 'd', area.y0(height)
    svg.append('clipPath').attr('id', 'clip-above').append('path').attr 'd', area.y0(0)
    svg.append('path').attr('class', 'area above').attr('clip-path', 'url(#clip-above)').attr 'd', area.y0((d) ->
      y d['item2']
    )
    svg.append('path').attr('class', 'area below').attr('clip-path', 'url(#clip-below)').attr 'd', area
    svg.append('path').attr('class', 'line').attr 'd', line
    svg.append('g').attr('class', 'x axis').attr('transform', 'translate(0,' + height + ')').call xAxis
    svg.append('g').attr('class', 'y axis').call(yAxis).append('text').attr('transform', 'rotate(-90)').attr('y', 6).attr('dy', '.71em').style('text-anchor', 'end').text 'Temperature (ºF)'
