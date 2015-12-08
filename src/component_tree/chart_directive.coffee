ComponentDirective = require('./component_directive')

module.exports = class ChartDirective extends ComponentDirective

  isChart: true

  setChartData: (data) ->
    @component.content[@name] ?= {}
    @component.content[@name].data = data
