class @TTY
  FORMATTERS = []
  STICKY_SCROLL_TOLERENCE = 200

  @appendFormatter: (formatter) ->
    FORMATTERS.push(formatter)

  @prependFormatter: (formatter) ->
    FORMATTERS.unshift(formatter)

  constructor: ($body) ->
    @$code = $body.find('code')
    @scrolling = new Scrolling(@$code)

  popInitialOutput: ->
    output = @$code.text()
    @$code.empty()
    output

  formatChunks: (chunk) ->
    for formatter in FORMATTERS
      chunk = formatter(chunk) || chunk
    chunk

  appendChunk: (chunk) =>
    @scrolling.preserve =>
      @$code.append(@formatChunks(chunk.raw))

class Scrolling
  TOLERENCE = 200

  constructor: (@$code) ->
    @$window = $(window)
    @initialScroll = true

  preserve: (callback) ->
    wasScrolledToBottom = @isScrolledToBottom()
    callback()
    if wasScrolledToBottom
      @$window.scrollTop(@codeBottomPosition() - @$window.height() + 50)

  isScrolledToBottom: ->
    if @initialScroll
      @initialScroll = (window.scrollY == 0)
      true
    else
      codeBottom = @codeBottomPosition()
      codeBottom + TOLERENCE > @viewportBottomPosition() >= codeBottom - TOLERENCE

  viewportBottomPosition: ->
    window.scrollY + @$window.height()

  codeBottomPosition: ->
    @$code.position().top + @$code.height()
