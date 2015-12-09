d3 = require('d3')
module.exports =

  display: (data, size, svg) ->
    margin =
      top: 5
      right: 40
      bottom: 20
      left: 120
    width = size.width
    height = size.height
    radius = Math.min(width, height) / 2
    color = d3.scale.ordinal().range([
      '#98abc5'
      '#8a89a6'
      '#7b6888'
      '#6b486b'
      '#a05d56'
      '#d0743c'
      '#ff8c00'
    ])
    arc = d3.svg.arc().outerRadius(radius - 10).innerRadius(0)
    labelArc = d3.svg.arc().outerRadius(radius - 40).innerRadius(radius - 40)
    pie = d3.layout.pie().sort(null).value((d) ->
      d.population
    )
    svg.attr('width', width).attr('height', height).append('g').attr('transform', 'translate(' + width / 2 + ',' + height / 2 + ')')

    data.forEach (d) ->
      g = svg.selectAll('.arc').data(pie(data)).enter().append('g').attr('class', 'arc')
      g.append('path').attr('d', arc).style 'fill', (d) ->
        color d.data.age
      g.append('text').attr('transform', (d) ->
        'translate(' + labelArc.centroid(d) + ')'
      ).attr('dy', '.35em').text (d) ->
        d.data.age
