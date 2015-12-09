d3 = require('d3')
module.exports =

  display: (id, size, fData) ->
    barColor = 'steelblue'
    # compute total for each state.

    segColor = (c) ->
      {
      low: '#807dba'
      mid: '#e08214'
      high: '#41ab5d'
      }[c]

    # function to handle histogram.

    histoGram = (fD) ->
      hG = {}
      hGDim =
        t: 60
        r: 0
        b: 30
        l: 0

      mouseover = (d) ->
        # utility function to be called on mouseover.
        # filter for selected state.
        st = fData.filter((s) ->
          s.State == d[0]
        )[0]
        nD = d3.keys(st.freq).map((s) ->
          {
          type: s
          freq: st.freq[s]
          }
        )
        # call update functions of pie-chart and legend.
        pC.update nD
        leg.update nD
        return

      mouseout = (d) ->
        # utility function to be called on mouseout.
        # reset the pie-chart and legend.
        pC.update tF
        leg.update tF
        return

      hGDim.w = size.width - (hGDim.l) - (hGDim.r)
      hGDim.h = size.height - (hGDim.t) - (hGDim.b)
      #create svg for histogram.
      hGsvg = d3.select(id).append('svg').attr('width', hGDim.w + hGDim.l + hGDim.r).attr('height', hGDim.h + hGDim.t + hGDim.b).append('g').attr('transform', 'translate(' + hGDim.l + ',' + hGDim.t + ')')
      # create function for x-axis mapping.
      x = d3.scale.ordinal().rangeRoundBands([
        0
        hGDim.w
      ], 0.1).domain(fD.map((d) ->
        d[0]
      ))
      # Add x-axis to the histogram svg.
      hGsvg.append('g').attr('class', 'x axis').attr('transform', 'translate(0,' + hGDim.h + ')').call d3.svg.axis().scale(x).orient('bottom')
      # Create function for y-axis map.
      y = d3.scale.linear().range([
        hGDim.h
        0
      ]).domain([
        0
        d3.max(fD, (d) ->
          d[1]
        )
      ])
      # Create bars for histogram to contain rectangles and freq labels.
      bars = hGsvg.selectAll('.bar').data(fD).enter().append('g').attr('class', 'bar')
      #create the rectangles.
      bars.append('rect').attr('x', (d) ->
        x d[0]
      ).attr('y', (d) ->
        y d[1]
      ).attr('width', x.rangeBand()).attr('height', (d) ->
        hGDim.h - y(d[1])
      ).attr('fill', barColor).on('mouseover', mouseover).on 'mouseout', mouseout
      # mouseout is defined below.
      #Create the frequency labels above the rectangles.
      bars.append('text').text((d) ->
        d3.format(',') d[1]
      ).attr('x', (d) ->
        x(d[0]) + x.rangeBand() / 2
      ).attr('y', (d) ->
        y(d[1]) - 5
      ).attr 'text-anchor', 'middle'
      # create function to update the bars. This will be used by pie-chart.

      hG.update = (nD, color) ->
        # update the domain of the y-axis map to reflect change in frequencies.
        y.domain [
          0
          d3.max(nD, (d) ->
            `var bars`
            d[1]
          )
        ]
        # Attach the new data to the bars.
        bars = hGsvg.selectAll('.bar').data(nD)
        # transition the height and color of rectangles.
        bars.select('rect').transition().duration(500).attr('y', (d) ->
          y d[1]
        ).attr('height', (d) ->
          hGDim.h - y(d[1])
        ).attr 'fill', color
        # transition the frequency labels location and change value.
        bars.select('text').transition().duration(500).text((d) ->
          d3.format(',') d[1]
        ).attr 'y', (d) ->
          y(d[1]) - 5
        return

      hG

    # function to handle pieChart.

    pieChart = (pD) ->
      pC = {}
      pieDim =
        w: 250
        h: 250
      # Utility function to be called on mouseover a pie slice.

      mouseover = (d) ->
        # call the update function of histogram with new data.
        hG.update fData.map((v) ->
          [
            v.State
            v.freq[d.data.type]
          ]
        ), segColor(d.data.type)
        return

      #Utility function to be called on mouseout a pie slice.

      mouseout = (d) ->
        # call the update function of histogram with all data.
        hG.update fData.map((v) ->
          [
            v.State
            v.total
          ]
        ), barColor
        return

      # Animating the pie-slice requiring a custom function which specifies
      # how the intermediate paths should be drawn.

      arcTween = (a) ->
        i = d3.interpolate(@_current, a)
        @_current = i(0)
        (t) ->
          arc i(t)

      pieDim.r = Math.min(pieDim.w, pieDim.h) / 2
      # create svg for pie chart.
      piesvg = d3.select(id).append('svg').attr('width', pieDim.w).attr('height', pieDim.h).append('g').attr('transform', 'translate(' + pieDim.w / 2 + ',' + pieDim.h / 2 + ')')
      # create function to draw the arcs of the pie slices.
      arc = d3.svg.arc().outerRadius(pieDim.r - 10).innerRadius(0)
      # create a function to compute the pie slice angles.
      pie = d3.layout.pie().sort(null).value((d) ->
        d.freq
      )
      # Draw the pie slices.
      piesvg.selectAll('path').data(pie(pD)).enter().append('path').attr('d', arc).each((d) ->
        @_current = d
        return
      ).style('fill', (d) ->
        segColor d.data.type
      ).on('mouseover', mouseover).on 'mouseout', mouseout
      # create function to update pie-chart. This will be used by histogram.

      pC.update = (nD) ->
        piesvg.selectAll('path').data(pie(nD)).transition().duration(500).attrTween 'd', arcTween
        return

      pC

    # function to handle legend.

    legend = (lD) ->
      `var legend`
      leg = {}
      # create table for legend.
      legend = d3.select(id).append('table').attr('class', 'legend')
      # create one row per segment.
      tr = legend.append('tbody').selectAll('tr').data(lD).enter().append('tr')
      # create the first column for each segment.

      getLegend = (d, aD) ->
        # Utility function to compute percentage.
        d3.format('%') d.freq / d3.sum(aD.map((v) ->
          v.freq
        ))

      tr.append('td').append('svg').attr('width', '16').attr('height', '16').append('rect').attr('width', '16').attr('height', '16').attr 'fill', (d) ->
        segColor d.type
      # create the second column for each segment.
      tr.append('td').text (d) ->
        d.type
      # create the third column for each segment.
      tr.append('td').attr('class', 'legendFreq').text (d) ->
        d3.format(',') d.freq
      # create the fourth column for each segment.
      tr.append('td').attr('class', 'legendPerc').text (d) ->
        getLegend d, lD
      # Utility function to be used to update the legend.

      leg.update = (nD) ->
        # update the data attached to the row elements.
        l = legend.select('tbody').selectAll('tr').data(nD)
        # update the frequencies.
        l.select('.legendFreq').text (d) ->
          d3.format(',') d.freq
        # update the percentage column.
        l.select('.legendPerc').text (d) ->
          getLegend d, nD
        return

      leg

    fData.forEach (d) ->
      d.total = d.freq.low + d.freq.mid + d.freq.high
      return
    # calculate total frequency by segment for all state.
    tF = [
      'low'
      'mid'
      'high'
    ].map((d) ->
      {
      type: d
      freq: d3.sum(fData.map((t) ->
        t.freq[d]
      ))
      }
    )
    # calculate total frequency by state for all segment.
    sF = fData.map((d) ->
      [
        d.State
        d.total
      ]
    )
    hG = histoGram(sF)
    pC = pieChart(tF)
    leg = legend(tF)
    # create the legend.
    return

