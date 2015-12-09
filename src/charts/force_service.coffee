d3 = require('d3')
donut = require('../charts/donut')
module.exports =

  display: (data, size, svg) ->
    width = 960
    height = 500
    json = data
    svg.attr('width', width).attr('height', height)
    force = d3.layout.force().gravity(.05).distance(100).charge(-100).size([
      width
      height
    ])
    force.nodes(json.nodes).links(json.links).start()
    link = svg.selectAll('.link').data(json.links).enter().append('line').attr('class', 'link')
    node = svg.selectAll('.node').data(json.nodes).enter().append('g').attr('class', 'node').call(force.drag)
    node.append('image').attr('x', -8).attr('y', -8).attr('width', 16).attr('height', 16).attr('xlink:href', (d) ->
      if d.group == 1
        'https://inception.woodwing.com/63/assets/images/favicon-32x32.png'
      else if d.group == 2
        'https://elvis.woodwing.com/img/favicon.a23aa4e3.ico'
      else
        'https://github.com/favicon.ico'
    )
    node.append('text').attr('dx', 12).attr('dy', '.35em').text (d) ->
      d.name
    force.on 'tick', ->
      link.attr('x1', (d) ->
        d.source.x
      ).attr('y1', (d) ->
        d.source.y
      ).attr('x2', (d) ->
        d.target.x
      ).attr 'y2', (d) ->
        d.target.y
      node.attr 'transform', (d) ->
        'translate(' + d.x + ',' + d.y + ')'
      return
