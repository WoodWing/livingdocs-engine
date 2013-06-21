describe 'HtmlCompare', ->
  compare = $.proxy(htmlCompare, 'compare')

  describe 'single elment', ->

    it 'considers the same elements equivalent', ->
      a = $("<div></div>")[0]
      b = $("<div></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'spots the difference between a div and a span', ->
      a = $("<div></div>")[0]
      b = $("<span></span>")[0]
      expect( compare(a, b) ).toBe(false)


  describe 'attributes', ->

    it 'considers the same attributes equivalent', ->
      a = $("<div id='a'></div>")[0]
      b = $("<div id='a'></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'ignores attribute order', ->
      a = $("<div id='a' class='hero'></div>")[0]
      b = $("<div class='hero' id='a'></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'spots different attribute values', ->
      a = $("<div id='a'></div>")[0]
      b = $("<div id='b'></div>")[0]
      expect( compare(a, b) ).toBe(false)


    it 'spots a missing attribute', ->
      a = $("<div id='a'></div>")[0]
      b = $("<div></div>")[0]
      expect( compare(a, b) ).toBe(false)


    it 'spots different attribute names', ->
      a = $("<div -x-a='one'></div>")[0]
      b = $("<div -x-b='one'></div>")[0]
      expect( compare(a, b) ).toBe(false)


    it 'spots a missing attribute among two', ->
      a = $("<div id='a' class='hero'></div>")[0]
      b = $("<div class='hero'></div>")[0]
      expect( compare(a, b) ).toBe(false)


    it 'considers the same empty attributes equivalent', ->
      a = $("<div contenteditable></div>")[0]
      b = $("<div contenteditable></div>")[0]
      expect( compare(a, b) ).toBe(true)


  describe 'class attribute', ->

    it 'considers the same classes in the same order equivalent', ->
      a = $("<div class='a b c'></div>")[0]
      b = $("<div class='a b c'></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'ignores ordering of classes', ->
      a = $("<div class='a b c'></div>")[0]
      b = $("<div class='c a b'></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'considers no classes equivalent', ->
      a = $("<div class=''></div>")[0]
      b = $("<div class=''></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'spots different classes', ->
      a = $("<div class='a b c'></div>")[0]
      b = $("<div class='a c'></div>")[0]
      expect( compare(a, b) ).toBe(false)


  describe 'style attribute', ->

    it 'considers the same styles equivalent', ->
      a = $("<div style='display:none'></div>")[0]
      b = $("<div style='display:none'></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'ignores different formatting', ->
      a = $("<div style='display:none'></div>")[0]
      b = $("<div style='display:none;'></div>")[0]
      expect( compare(a, b) ).toBe(true)

      b = $("<div style='display: none'></div>")[0]
      expect( compare(a, b) ).toBe(true)

      b = $("<div style=' display :none;'></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'ignores ordering and formatting', ->
      a = $("<div style='border-radius:5px;position:absolute'></div>")[0]
      b = $("<div style=' position : absolute; border-radius : 5px; '></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'spots a tiny difference in border', ->
      a = $("<div style='display:none; border: 1px solid #000'></div>")[0]
      b = $("<div style='display:none; border: 2px solid #000'></div>")[0]
      expect( compare(a, b) ).toBe(false)


    it 'spots a surplus colon', ->
      a = $("<div style='display:none; border: 1px solid #000'></div>")[0]
      b = $("<div style='display::none; border: 1px solid #000'></div>")[0]
      expect( compare(a, b) ).toBe(false)


  describe 'text', ->

    it 'normalizes whitespace by default', ->
      expect(htmlCompare.normalizeWhitespace).toBe(true)


    it 'considers the same text equivalent', ->
      a = $("<div>text</div>")[0]
      b = $("<div>text</div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'collapses whitespace inside of text', ->
      a = $("<div>mind the gap</div>")[0]
      b = $("<div>mind  the gap</div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'ignores whitespace at the end', ->
      a = $("<div>text</div>")[0]
      b = $("<div>text </div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'considers newline and whitespace the same', ->
      a = $("<div>text on a new line</div>")[0]
      b = $("<div>text\non\na\nnew\nline</div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'spots different text', ->
      a = $("<div>text</div>")[0]
      b = $("<div>tex</div>")[0]
      expect( compare(a, b) ).toBe(false)


  describe 'text with a link', ->

    it 'considers the same equivalent', ->
      a = $("<div><a href='/'></a></div>")[0]
      b = $("<div><a href='/'></a></div>")[0]
      expect( compare(a, b) ).toBe(true)


  describe 'empty text nodes', ->

    it 'ignores them between elements', ->
      a = $("<div> <span></span></div>")[0]
      b = $("<div><span></span></div>")[0]
      expect( compare(a, b) ).toBe(true)


  describe 'single nested element', ->

    it 'considers the same equivalent', ->
      a = $("<div><span></span></div>")[0]
      b = $("<div><span></span></div>")[0]
      expect( compare(a, b) ).toBe(true)


    it 'spots a different nested element', ->
      a = $("<div><span></span></div>")[0]
      b = $("<div><a></a></div>")[0]
      expect( compare(a, b) ).toBe(false)
