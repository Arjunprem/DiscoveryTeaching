MakeScopeLectureChannel = function(room,id) {
    if (typeof App['scopeLectureChannel'] === "undefined") App.scopeLectureChannel={};
    if (typeof App.scopeLectureChannel[room+id] === "object") return false;

    App.scopeLectureChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeLectureChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeLectureChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeLectureChannel '+room+id)},
        received: function(data) {
                for (var i = 0; i < data.html.length; i++) {
                    var type = data.type;
                    switch (type) {
                        case 'update':
                            var itemId = $(data.html[i]).data('item-lecture'),
                                element = $('body').find("[data-item-lecture="+itemId+"]");

                            element.replaceWith(data.html[i]);
                            break;
                        case 'destroy':
                            var itemId = $(data.html[i]).data('item-lecture'),
                                element = $('body').find("[data-item-lecture="+itemId+"]");
                            element.remove();
                            break;
                        case 'new':
                            var parent = $('body').find("[data-item-lecture-parent]");
                            parent.prepend(data.html[0]);
                            return;
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