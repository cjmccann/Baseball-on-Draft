function initRenameMenus() {
    $.contextMenu('destroy', '.editName');

    $.contextMenu({
        selector: '.editName', 
        className: 'data-team-name',
        trigger: 'left',
        items: {
            name: {
                name: "New name",
                type: 'text',
            },
            sep1: '---------',
            submit: {
                name: 'Submit',
                callback: submitNewTeamName
            }
        },
    });
}

function submitNewTeamName(e, options) {
    newName = $('.data-team-name').find('input').val();
    teamId = $(this).closest('tr').data('team-id');

    if (newName != "") {
        $.ajax({
            type: 'POST',
            url: '/leagues/' + getLeagueId() + '/changeTeamName',
            data: {
                'teamId': teamId,
                'newName': newName,
            },
            error: function(xhr, status) {
                console.log("ajax error in addPlayerToTeam");
                debugger;
            },
        });
    }
}

function getLeagueId() {
    return $('.league').data('league-id');
}

league_ready = function() {
    initRenameMenus();
}

document.addEventListener('turbolinks:load', league_ready);
