d3 = require('d3')
donut = require('../charts/donut')
module.exports =

  display: (data, size, svg) ->
    svg = d3.select('body').append('svg').attr('width', size.width).attr('height', size.height)
    svg.append('g').attr 'id', 'salesDonut'
    svg.append('g').attr 'id', 'quotesDonut'
    Donut3D.draw 'salesDonut', @randomData(data), 150, 150, 130, 100, 30, 0.4
    Donut3D.draw 'quotesDonut', (data), 450, 150, 130, 100, 30, 0

  randomData: (data) ->
    data.map (d) ->
      {
      label: d.label
      value: 1000 * Math.random()
      color: d.color
      }
