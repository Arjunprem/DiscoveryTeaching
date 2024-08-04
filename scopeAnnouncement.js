MakeScopeAnnouncementChannel = function(room,id) {
    if (typeof App['scopeAnnouncementChannel'] === "undefined") App.scopeAnnouncementChannel={};
    if (typeof App.scopeAnnouncementChannel[room+id] === "object") return false;

    App.scopeAnnouncementChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeAnnouncementChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeAnnouncementChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeAnnouncementChannel '+room+id)},
        received: function(data) {
            for (var i = 0; i < data.html.length; i++) {
                   var  type = data.type;

                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-announcement'),
                        element = $('body').find("[data-item-announcement="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-announcement'),
                            element = $('body').find("[data-item-announcement="+itemId+"]");
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-announcement-parent]");
                        parent.prepend(data.html[i]);
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