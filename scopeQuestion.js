MakeScopeQuestionChannel = function(room,id) {
    if (typeof App['scopeQuestionChannel'] === "undefined") App.scopeQuestionChannel={};
    if (typeof App.scopeQuestionChannel[room+id] === "object") return false;

    App.scopeQuestionChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeQuestionChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeQuestionChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeQuestionChannel '+room+id)},
        received: function(data) {
            for (var i = 0; i < data.html.length; i++) {
                var  type = data.type;
                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-question'),
                            element = $('body').find("[data-item-question="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-question'),
                            element = $('body').find("[data-item-question="+itemId+"]");
                        console.log(itemId);
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-question-parent]");
                        parent.append(data.html[i]);
                        break;
                    default:
                        console.error('type not found')
                }
            }
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};