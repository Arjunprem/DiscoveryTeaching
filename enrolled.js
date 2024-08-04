MakeEnrolledChannel = function(room,id) {
    if (typeof App['enrolled'] === "undefined") App.enrolled={};
    App.enrolled[room+id] = App.cable.subscriptions.create({
        channel: "EnrolledChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect EnrolledChannel'+room+id)},
        disconnected: function() {console.log('disconnected EnrolledChannel'+room+id)},
        received: function(data) {
            return  $("#enrolledCount_"+id).html(data.enrolledCount);

        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};