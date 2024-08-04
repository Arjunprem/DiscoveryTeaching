MakeTaskChannel = function(room,id) {
    if (typeof App['task'] === "undefined") App.task={};
    App.task[room+id] = App.cable.subscriptions.create({
        channel: "TaskChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect TaskChannel'+room+id)},
        disconnected: function() {console.log('disconnected TaskChannel'+room+id)},
        received: function(data) {
            return $("#tasksCount_"+id).html(data.tasksCount);
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};