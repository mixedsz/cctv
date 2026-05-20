$(function(){
    $.post(`https://${GetParentResourceName()}/loaded`)

    let hours = 0
    let mins = 0
    let seconds = 0

    setInterval(function(){
        let currentDate = new Date();
        let currentTime = addZero(currentDate.getHours()) + ":" + addZero(currentDate.getMinutes());
        let date = currentDate.getDate() + "/" + (currentDate.getMonth() + 1) + "/" + currentDate.getFullYear();

        $(".date").text(date);
        $(".time").text(currentTime);

        seconds = seconds + 1

        if (seconds == 60) {
            mins = mins + 1
            seconds = 0
        }

        if (mins == 60) {
            hours = hours + 1
            mins = 0
        }

        $(".time-passed").text(addZero(hours) + ":" + addZero(mins) + ":" + addZero(seconds));
    }, 1000)

    window.addEventListener('message', function(event) {
        var data = event.data;

        if (data.action === "loggedIn"){
            let name = data.name
            let job = data.job
            let grade = data.grade

            $(".police-name").text(name)
            $(".police-job").text(job + " - " + grade)

            console.log("Updated police data")
        }

        if (data.action === "toggleUi") {
            if (data.status == true) {
                $('main').fadeIn();
                $(".camera-name").text(data.camData.cameraName);
                $(".street").text(data.street);
                $(".road").text(data.zone);

                $(".camera-type-buttons .btn").removeClass("active")
                $(".camera-type-buttons .btn:first-child").addClass("active")
            } else {
                $('main').fadeOut();
            }
        }

        if (data.action === "showPlayerData"){
            let playerName = data.playerData.name
            let playerImage = data.playerData.image
            let type = data.playerData.type
            let playerRole = data.playerData.role || "Citizen"
            let playerArmed = data.playerData.armed || "UNARMED"

            $(".player-name").text(playerName)
            if (type == "vehicle"){
                $(".player-image img").attr("src", `https://raw.githubusercontent.com/MericcaN41/gta5carimages/main/images/${(playerName).toLowerCase()}.png`)
            }else{
                $(".player-image img").attr("src", playerImage)
            }
            $(".player-role").text(playerRole)
            $(".player-armed").text(playerArmed)

            $(".player-data").show()
            $(".player-data").css("display", "flex")
        }

        if (data.action === "hidePlayerData"){
            $(".player-data").hide()
        }

        if (data.action === "updateCompassData"){
            let heading = convertValue(data.heading, 0, 360, 39, -61)
            $(".top-center .scroll").css("transform", `translateX(${heading}%)`)
        }
    });

    $(".camera-type-buttons .btn").click(function(){
        $(".camera-type-buttons .btn").removeClass("active")
        $(this).addClass("active")
    })

    $(document).keydown(function(e){
        if (e.which == 17) {
            $.post(`https://${GetParentResourceName()}/nuiFocus`)
        }
    })
})

function addZero(i) {
    if (i < 10) {i = "0" + i}
    return i;
}

function changeType(type) {
    $.post(`https://${GetParentResourceName()}/changeType`, JSON.stringify({type: type}))
}

function convertValue(value, oldMin, oldMax, newMin, newMax) {
    const oldRange = oldMax - oldMin
    const newRange = newMax - newMin
    const newValue = ((value - oldMin) * newRange) / oldRange + newMin
    return newValue
}