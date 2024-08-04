MakeQuestionChannel = function(room,id) {
    if (typeof App['question'] === "undefined") App.question={};
    App.question[room+id] = App.cable.subscriptions.create({
        channel: "QuestionChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect QuestionChannel'+room+id)},
        disconnected: function() {console.log('disconnected QuestionChannel'+room+id)},
        received: function(data) {
            console.log(data);
            return $("#questionsCount_"+id).html(data.questionsCount);
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};