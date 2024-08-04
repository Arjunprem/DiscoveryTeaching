MakeScopeAnswerChannel = function(room,id) {
    if (typeof App['response'] === "undefined") App.scopeAnswerChannel={};
    App.scopeAnswerChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeAnswerChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeAnswerChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeAnswerChannel '+room+id)},
        received: function(data) {

                for (var i = 0; i < data.html.length; i++) {
                    var itemId = $(data.html[i]).data('item-lecture'),
                        type = data.type,
                        element = $('body').find("[dat a-item-lecture="+itemId+"]");
                        if (!element.length) continue;

                    switch (type) {
                        case 'update':
                            element.replaceWith(data.html[i]);
                            break;
                        case 'destroy':
                            element.remove();
                            break;
                        case 'new':
                            var parent = $('body').find("[data-item-lecture]").parent();
                            parent.prepend(data.html);
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