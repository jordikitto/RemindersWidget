update: (output, domEl) ->
    # Widget Settings
    tasksPerList = 0    # Number of tasks to show per list, 0 for all
    showNotes = true   # Whether notes get shown. Either true or false
    listsToNotShow = [] # Or leave empty as [] to show all
    monthBeforeDay = false # For American's and such. Either true or false
 
    # Do not alter below here
    str = '<ul class="lists">'
    listNameTpl = ''
    reminders = JSON.parse(output)
    listTasks = @tasksByList(output)

    if !@content
        @content = $(domEl).find('.reminders-wrap').html(str)
    for listName in reminders.lists.sort().reverse() # For each list
    		if listName not in listsToNotShow
                n = 0
                if listTasks[listName]? # if tasks exist
                    n = if tasksPerList > 0 and listTasks[listName].length > tasksPerList then tasksPerList else listTasks[listName].length
                if n > 0 # if there are tasks in the list
                    # Add list name to title, and number of tasks shown if not all are being shown
                    if tasksPerList <= 0
                        listNameTpl = '<div class="list-info">' +
                        '<div class="list-name">' + listName + '</div>' +
                        '</div>'
                    else if tasksPerList > 0
                        listNameTpl = '<div class="list-info">' +
                        '<div class="list-name">' + listName + '</div>' +
                        '<div class="tasks-length">' + n + ' of ' + listTasks[listName].length + '</div>' +
                        '</div>'
                    str +=  '<li class="list">' + listNameTpl + '<ul class="tasks">'

                    i = 0
                    for task in listTasks[listName]
                        priority =  switch(task.priority)
                            when "1" then '!!!'
                            when "5" then '!!'
                            when "9" then '!'
                            else ''
                        if i < n
                            task = listTasks[listName][i]
                            notes = if showNotes and task.notes then task.notes else ''
                            str += '<li class="task">' +
                                '<mark class="priority">' + priority + '</mark> ' + task.title
                            if task.dueDate != " "
                                now = new Date()
                                d = new Date(task.dueDate)

                                # - - Formatting - -
                                # Format times and dates
                                hours = d.getHours();
                                minutes = d.getMinutes();

                                if hours >= 12
                                    ampm = 'pm'
                                else
                                    ampm = 'am'

                                hours = hours % 12;
                                if hours == 0 # the hour '0' should be '12'
                                    hours = 12

                                if minutes < 10
                                    minutes = '0'+minutes # Append leading zero

                                timeStr = hours + ':' + minutes + ' ' + ampm;
                                if monthBeforeDay
                                    dateStr = (d.getMonth() + 1) + '/' + d.getDate()
                                else
                                    dateStr = d.getDate() + '/' + (d.getMonth() + 1)
                                # End format times and dates

                                # - - Natural wording - -
                                tomorrow = new Date()
                                tomorrow.setDate(now.getDate() + 1)
                                yesterday = new Date()
                                yesterday.setDate(now.getDate() - 1)

                                # Calculate days between now and task due
                                oneDay = 24*60*60*1000; # hours*minutes*seconds*milliseconds
                                diffDays = Math.ceil(Math.abs((d.getTime() - now.getTime())/(oneDay)))

                                # format wording
                                if d.getDate() == now.getDate() && d.getMonth() == now.getMonth() && d.getFullYear() == now.getFullYear()
                                    dStr = 'today at ' + timeStr
                                else if d.getDate() == tomorrow.getDate() && d.getMonth() == tomorrow.getMonth() && d.getFullYear() == tomorrow.getFullYear()
                                    dStr = 'tomorrow at ' + timeStr
                                else if diffDays <= 7 && (d.getDate() > now.getDate() || d.getMonth() > now.getMonth() || d.getFullYear() > now.getFullYear())
                                    dStr = 'in ' + diffDays.toString() + ' days at ' + timeStr
                                else if d.getDate() == yesterday.getDate() && d.getMonth() == yesterday.getMonth() && d.getFullYear() == yesterday.getFullYear()
                                    dStr = 'yesterday at ' + timeStr
                                else if d.getFullYear() > now.getFullYear()
                                    dStr = dateStr + '/' + (d.getFullYear() - 2000) + ' at ' + timeStr
                                else
                                    dStr = dateStr + ' at ' + timeStr # Formatted date
                                # End formatting

                                divcls = if d < now then 'overdue' else 'due'
                                str += '<div class="' + divcls + '">Due ' + dStr + '</div>'
                            if showNotes and task.notes
                                str += '<div class="notes">' + task.notes + '</div>'
                            str += '</li>'
                            i++
                        else
                            break
                    str += '</ul></li>'
    str += '</ul>'
    @content.html(str)

# Set the refresh frequency (milliseconds).
refreshFrequency: '1m'

# Command
command: 'reminders.widget/pending.sh'

tasksByList: (output) ->
    reminders = JSON.parse(output)
    listTasks = {}
    for t in reminders.tasks
        listTasks[t.list] = [] if !listTasks[t.list]
        listTasks[t.list].push(t)
    return listTasks

# Most of the following was cribbed from
showError: (err) ->
	if @content
		@content.html '<div class="error">' + err + '</div>'

render: (output) -> """
	<div class='reminders-wrap'>
	</div>
"""

style: """
    top: 0%
    left: 0%
    color: #fff
    background: rgba(0,0,0,0.6)
    font-family: Arial
    font-size: 10pt
    width: 260px
    height: 100%
    /*-webkit-backdrop-filter: blur(10px) brightness(100%) contrast(50%) saturate(100%)*/


    .lists,.tasks
        margin: 0
        padding: 0

    .list,.task
        list-style: none
        padding-top: 6%

    .list-info
        background: rgba(0,0,0,0.5)
        position: relative
        font-weight: bold

    .list-name
        padding: 5px 10px
        margin: 0 40px 0 0
        overflow: hidden
        position: relative
        white-space: nowrap
        opacity: 0.85

    .tasks-length
        position: absolute
        top: 0px
        right: 5px
        opacity: 100%
        padding: 5px 5px

    .task
        margin: 0 10px
        padding: 5px 0 5px 20px
        position: relative
        opacity: 0.85

    .task::after
        content: ""
        position: absolute
        width: 10px
        height: 10px
        background: rgba(0,0,0,0.2)
        -webkit-border-radius: 20px
        border-style: solid
        border-color: rgba(190, 133, 42, 1);
        left: 0px
        top: 4px

    .due
        text-decoration: underline

    .overdue
        text-decoration: underline
        color: red

    .notes
        font-style: oblique

    mark
        color: red
        background-color: transparent

    .error
        padding: 5px
        background: rgba(0,0,0,0.3)
"""

afterRender: (domEl)->
  $(domEl).on 'click', => @run "open /Applications/Reminders.app"