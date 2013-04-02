root = exports ? this

root.socket = io.connect 'http://localhost'

class AppRouter extends Backbone.Router

  routes:
   '': 'index'
   '/': 'index'

  index: ->

    todos = new Todos
    form = new TodoListForm todos
    $('#TodoWrapper').append(form.el)
    list = new TodoList(todos)
    $('#TodoWrapper').append(list.el)
    todos.fetch()
# Model
class Todo extends Backbone.Model
  
  urlRoot: 'todo'
  noIoBind: false
  socket: root.socket

  initialize: ->
    
    _.bindAll(this, 'serverChange', 'serverDelete', 'modelCleanup')
    

    if not @noIoBind
      
      @ioBind 'update', @serverChange, this
      @ioBind 'delete', @serverDelete, this

  serverChange: (data) ->
    data.fromServer = true
    @set data

  serverDelete: (data) ->
    if @collection
      @collection.remove this
    else
      @trigger 'remove', this
    @modelCleanup()

  modelCleanup: ->
    @ioUnbindAll()
    this

# Collection
class Todos extends Backbone.Collection
  
  model: Todo
  url: 'todos'
  socket: root.socket

  initialize: ->
    
    _.bindAll(this, 'serverCreate', 'collectionCleanup')
    @ioBind 'create', @serverCreate, this

  serverCreate: (data)->
    # ensure no duplicates in the same page
    exists = @get data['id']

    if not exists
      @add data
    else
      data.fromServer = true
      exists.set data

  collectionCleanup: ->
    @ioUnbindAll()
    @forEach (model)->
      model.modeleCleanup()
    this

# Todos view
class TodoList extends Backbone.View
  
  id: 'TodoList'
  
  initialize: (todos)->
    
    @todos = todos
    _.bindAll(this, 'render', 'addTodo', 'removeTodo')
    @todos.bind "reset", @render
    @todos.bind "add", @addTodo
    @todos.bind "remove", @removeTodo
    @render()

  render: =>
    @todos.forEach (todo)=>
      @addTodo todo
    this

  addTodo: (todo)->
    tdv = new TodoListItem model: todo
    @$el.append tdv.el

  removeTodo: (todo)->
    self = this
    width = @$("#" + todo.id).outerWidth()

    # ooh, shiny animation!
    @$("#" + todo.id).css "width", width + "px"
    @$("#" + todo.id).animate
     "margin-left": width
     opacity: 0
    , 200, ->
     self.$("#" + todo.id).animate
       height: 0
     , 200, ->
       self.$("#" + todo.id).remove()

class TodoListItem extends Backbone.View
  
  className: 'todo'

  events: 
    'click .complete' : 'completeTodo'
    'click .delete' : 'deleteTodo'
  initialize: ->
    
    _.bindAll(this, 'setStatus', 'completeTodo', 'deleteTodo')
    @model.bind 'change:complete', @setStatus
    @render()

  render: ->
    @$el.html template.item(@model.toJSON())
    @$el.attr "id", @model.id
    @setStatus()
    this

  setStatus: ->
    status = @model.get 'completed'
    if status
      @$el.addClass 'complete'
    else
      @$el.removeClass 'complete'

  completeTodo: ->
    status = @model.get 'completed'
    @model.save 'completed': not status

  deleteTodo: ->
    console.log 'sssssss'
    @model.destroy silent: true

class TodoListForm extends Backbone.View
  id: 'TodoForm'

  events: 
    'click .button#add': 'addTodo'

  
  initialize: (todos)->
    @todos = todos
    _.bindAll(this, 'addTodo')
    @render()

  render: ()->
    @$el.html (template.form())
    this

  addTodo: ->
    Todo = Todo.extend noIoBind: true

    attrs = 
      title: @$('#TodoInput input[name="TodoInput"]').val()
      complete: false

    @$("#TodoInput input[name=\"TodoInput\"]").val ""
    _todo = new Todo(attrs)
    _todo.save()



$ ->
  app = new AppRouter
  Backbone.history.start()

  