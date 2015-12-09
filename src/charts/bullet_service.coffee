d3 = require('d3')
bullet = require('../charts/bullet')
module.exports =

  display: (data, size, $elem) ->
    margin =
      top: 5
      right: 40
      bottom: 20
      left: 120
    width = size.width - (margin.left) - (margin.right)
    height = size.height - (margin.top) - (margin.bottom)
    chart = d3.bullet().width(width).height(height)

    randomize = (d) ->
      if !d.randomizer
        d.randomizer = randomizer(d)
      d.ranges = d.ranges.map(d.randomizer)
      d.markers = d.markers.map(d.randomizer)
      d.measures = d.measures.map(d.randomizer)
      d

    randomizer = (d) ->
      k = d3.max(d.ranges) * .2
      (d) ->
        Math.max 0, d + k * (Math.random() - .5)

    d3element = d3.select($elem[0])
    svg = d3element.selectAll('svg').data(data).enter().append('svg').attr('class', 'bullet').attr('width', width + margin.left + margin.right).attr('height', height + margin.top + margin.bottom).append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')').call(chart)
    title = svg.append('g').style('text-anchor', 'end').attr('transform', 'translate(-6,' + height / 2 + ')')
    title.append('text').attr('class', 'title').text (d) ->
      d.title
    title.append('text').attr('class', 'subtitle').attr('dy', '1em').text (d) ->
      d.subtitle
    d3.selectAll('button').on 'click', ->
      svg.datum(randomize).call chart.duration(1000)
      return
