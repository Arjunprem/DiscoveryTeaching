MakeReviewChannel = function(room,id) {
    if (typeof App['review'] === "undefined") App.review={};
    App.review[room+id] = App.cable.subscriptions.create({
        channel: "ReviewChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ReviewChannel'+room+id)},
        disconnected: function() {console.log('disconnected ReviewChannel'+room+id)},
        received: function(data) {
            return $("#reviewsCount_"+data.question_id).html(data.reviewsCount + " Reviews&nbsp;&nbsp;");
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};