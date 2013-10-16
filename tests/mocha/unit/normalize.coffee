describe('Normalize', ->
  describe('breakLine', ->
    blockTest = new ScribeHtmlTest(
      expected: [
        '<div><span>One</span></div>'
        '<div><span>Two</span></div>'
      ]
      fn: (container) ->
        ScribeNormalizer.breakLine(container.firstChild, container)
    )

    blockTest.run('Inner divs', 
      initial: [
        '<div>
          <div><span>One</span></div>
          <div><span>Two</span></div>
        </div>'
      ]
    )

    blockTest.run('Nested inner divs', 
      initial: [
        '<div>
          <div><div><span>One</span></div></div>
          <div><div><span>Two</span></div></div>
        </div>'
      ]
    )
  )

  describe('normalizeBreak', ->
    breakTest = new ScribeHtmlTest(
      fn: (container) ->
        ScribeNormalizer.normalizeBreak(container.querySelector('br'), container)
    )

    breakTest.run('Break in middle of line', 
      initial:  [
        '<div><b>One<br />Two</b></div>'
      ]
      expected: [
        '<div><b>One</b></div>'
        '<div><b>Two</b></div>'
      ]
    )

    breakTest.run('Break preceding line', 
      initial: [
        '<div><b><br />One</b></div>'
      ]
      expected: [
        '<div><b><br /></b></div>'
        '<div><b>One</b></div>'
      ]
    )

    breakTest.run('Break after line', 
      initial:  ['<div><b>One<br /></b></div>']
      expected: ['<div><b>One</b></div>']
    )
  )

  describe('groupBlocks', ->
    groupTest = new ScribeHtmlTest(
      fn: (container) ->
        ScribeNormalizer.groupBlocks(container)
    )

    groupTest.run('Wrap newline', 
      initial:  ['<br />']
      expected: ['<div><br /></div>']
    )

    groupTest.run('Wrap span', 
      initial:  ['<span>One</span>']
      expected: ['<div><span>One</span></div>']
    )

    groupTest.run('Wrap many spans', 
      initial: [
        '<div><span>One</span></div>'
        '<span>Two</span>'
        '<span>Three</span>'
        '<div><span>Four</span></div>'
      ]
      expected: [
        0, '<div><span>Two</span><span>Three</span></div>', 3
      ]
    )

    groupTest.run('Wrap break and span', 
      initial:  ['<br /><span>One</span>']
      expected: ['<div><br /><span>One</span></div>']
    )
  )

  describe('normalizeLine', ->
    normalizer = null
    before( ->
      container = $('#test-container').get(0)
      formatManager = new ScribeFormatManager(container)
      normalizer = new ScribeNormalizer(container, formatManager)
    )

    lineTest = new ScribeHtmlTest(
      fn: (lineNode) ->
        normalizer.normalizeLine(lineNode)
    )

    lineTest.run('preserve style attributes', 
      initial: 
        '<span style="font-size: 32px;">Huge</span>
        <span style="color: rgb(255, 0, 0);">Red</span>
        <span style="font-family: \'Times New Roman\', serif;">Serif</span>
        <span style="font-size: 18px;">Large</span>'
      expected:
        '<span style="font-size: 32px;">Huge</span>
        <span style="color: rgb(255, 0, 0);">Red</span>
        <span style="font-family: \'Times New Roman\', serif;">Serif</span>
        <span style="font-size: 18px;">Large</span>'
    )

    lineTest.run('remove redundant format elements', 
      initial:  '<b><i><b>Bolder</b></i></b>'
      expected: '<b><i>Bolder</i></b>'
    )

    lineTest.run('remove redundant elements 1', 
      initial:  '<span><br></span>'
      expected: '<br />'
    )

    lineTest.run('remove redundant elements 2', 
      initial:  '<span><span>Span</span></span>'
      expected: '<span>Span</span>'
    )

    lineTest.run('remove redundant elements 3', 
      initial:  '<span class="nothing special"><span>Span</span></span>'
      expected: '<span>Span</span>'
    )

    lineTest.run('wrap text node', 
      initial:  'Hey'
      expected: '<span>Hey</span>'
    )

    lineTest.run('wrap text node next to element node', 
      initial:  'Hey<b>Bold</b>'
      expected: '<span>Hey</span><b>Bold</b>'
    )

    lineTest.run('unnecessary break', 
      initial:  '<span>One</span><br>'
      expected: '<span>One</span>'
    )
  )

  describe('normalizeDoc', ->
    docTest = new ScribeEditorTest(
      fn: (editor) ->
        editor.doc.normalizer.normalizeDoc()
    )

    docTest.run('empty string', 
      initial:  ['']
      expected: ['<div><br></div>']
    )

    docTest.run('lone break', 
      initial:  ['<br>']
      expected: ['<div><br></div>']
    )

    docTest.run('correct break', 
      initial:  ['<div><br></div>']
      expected: [0]
    )

    docTest.run('handle nonstandard block tags', 
      initial: [
        '<h1>
          <dl><dt>One</dt></dl>
          <pre>Two</pre>
          <p><span>Three</span></p>
        </h1>'
      ]
      expected: [
        '<div><span>One</span></div>'
        '<div><span>Two</span></div>'
        '<div><span>Three</span></div>'
      ]
    )

    docTest.run('handle nonstandard break tags', 
      initial: [
        '<div><b>One<br><hr>Two</b></div>'
      ]
      expected: [
        '<div><b>One</b></div>'
        '<div><br></div>'
        '<div><b>Two</b></div>'
      ]
    )

    docTest.run('tranform equivalent styles',
      initial: [
        '<div>
          <strong>Strong</strong>
          <del>Deleted</del>
          <em>Emphasis</em>
          <strike>Strike</strike>
          <b>Bold</b>
          <i>Italic</i>
          <s>Strike</s>
          <u>Underline</u>
        </div>'
      ]
      expected: [
        '<div>
          <b>Strong</b>
          <s>Deleted</s>
          <i>Emphasis</i>
          <s>Strike</s>
          <b>Bold</b>
          <i>Italic</i>
          <s>Strike</s>
          <u>Underline</u>
        </div>'
      ]
    )
  )

  describe('normalizeTags', ->
    normalizer = null
    before( ->
      container = $('#test-container').get(0)
      formatManager = new ScribeFormatManager(container)
      normalizer = new ScribeNormalizer(container, formatManager)
    )

    attrTest = new ScribeHtmlTest(
      fn: (lineNode) ->
        normalizer.normalizeTags(lineNode)
    )

    attrTest.run('strip extraneous attributes', 
      initial:  '<span data-test="test" width="100px">One</span>'
      expected: '<span>One</span>'
    )

    attrTest.run('strip extraneous attributes from tag', 
      initial:  '<b data-test="test" width="100px">Bold</b>'
      expected: '<b>Bold</b>'
    )

    attrTest.run('strip extraneous attributes from style tag', 
      initial:  '<span style="color: rgb(0, 255, 255);" data-test="test" width="100px">Color</span>'
      expected: '<span style="color: rgb(0, 255, 255);">Color</span>'
    )

    attrTest.run('separate multiple styles',
      initial: '<span style="background-color: rgb(255, 0, 0); color: rgb(0, 255, 255);">Color</span>'
      expected: '<span style="color: rgb(0, 255, 255);"><span style="background-color: rgb(255, 0, 0);">Color</span></span>'
    )

    attrTest.run('separate non-standard style',
      initial: '<span style="font-style:italic;">Italic</i>'
      expected: '<i>Italic</i>'
    )

    attrTest.run('separate style from non-span',
      initial: '<i style="color: rgb(0, 255, 255);">Color</i>'
      expected: '<span style="color: rgb(0, 255, 255);"><i>Color</i></span>'
    )

    attrTest.run('separate multiple styles from non-span',
      initial: '<i style="background-color: rgb(255, 0, 0); color: rgb(0, 255, 255);">Color</i>'
      expected: '<span style="background-color: rgb(255, 0, 0);"><span style="color: rgb(0, 255, 255);"><i>Color</i></span></span>'
    )
  )
)