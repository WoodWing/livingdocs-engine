# Document
# --------
# Manage the document content and its dependencies.
#
# ### Content:
# SnippetTree and corresponding DOM root node
#
# ### Assets:
# load and manage CSS and Javascript dependencies

document = do ->

  initialized: false
  snippets: {}
  uniqueId: 0


  # *Public API*
  loadDocument: ({ contentJson }={}) ->
    error("document is already initialized") if @initialized
    @initialized = true

    @snippetTree = if contentJson
      new SnippetTree()
    else
      new SnippetTree(content: contentJson)


    page.initializeSection(snippetTree: @snippetTree)


  # *Public API*
  addSnippetCollection: (snippetCollection) ->
    config = snippetCollection.config
    delete snippetCollection.config

    namespace = config?.namespace || "snippet"

    if config.css
      loader.css(config.css)

    @snippets[namespace] ||= {}

    for name, template of snippetCollection

      @snippets[namespace][name] = new SnippetTemplate
        namespace: namespace
        name: name
        html: template.html
        title: template.name


  # list available snippetTemplates
  listSnippets: ->
    for namespace, value of @snippets
      for name, snippet of value
        snippet.identifier



  # *Public API*
  add: (input) ->
    if jQuery.type(input) == "string"
      snippet = @createSnippet(input)
    else
      snippet = input

    @snippetTree.append(snippet) if snippet
    snippet


  # *Public API*
  createSnippet: (identifier) ->
    template = @getTemplate(identifier)
    template.create() if template


  # find all instances of a certain SnippetTemplate
  find: (identifier) ->
    res = []
    @snippetTree.each (snippet) ->
      res.push(snippet) if snippet.identifier == identifier

    res


  # print documentation for a snippet template
  help: (identifier) ->
    template = @getTemplate(identifier)
    template.printDoc()


  printTree: () ->
    @snippetTree.print()


  nextId: (prefix = "doc") ->
    @uniqueId += 1
    "#{ prefix }-#{ @uniqueId }"


  getTemplate: (identifier) ->
    { namespace, name } = SnippetTemplate.parseIdentifier(identifier)
    snippetTemplate = @snippets[namespace]?[name]

    if !snippetTemplate
      error("could not find template #{ identifier }")

    snippetTemplate

