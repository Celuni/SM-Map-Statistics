<?php
require ('config.php');
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
<!DOCTYPE html>
<html style="font-family:Lato, sans-serif;">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $browser_title; ?></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/animate.css/3.5.2/animate.min.css">
</head>

<body>
    <div>
        <h1 class="text-center" style="margin-top:15px;margin-bottom:15px;"><?php echo $page_title; ?><br></h1>
        <div class="container">
            <div class="row" style="margin-top:25px;">
                <div class="col-md-12">
                    <h1 style="margin-bottom:15px;">General Statistics</h1>
                </div>
                            <?php
                            $sql = "SELECT * FROM map_stats_total ORDER BY map_count DESC";
                            $result = $conn->query($sql);

                            if ($result->num_rows > 0) { 
                                echo '<div class="col-md-12">
                                <div class="table-responsive">
                                    <table class="table">
                                        <thead>
                                            <tr>
                                                <th>Map</th>
                                                <th>Total Times Played</th>
                                                <th>Total Player Count</th>
                                                <th>Match Average</th>
                                            </tr>
                                        </thead>
                                        <tbody>';
                                while ($row = $result->fetch_assoc()) {
                                    echo '<tr>
                                    <td>'.$row["map_name"].'</td>
                                    <td>'.$row["map_count"].'</td>
                                    <td>'.$row["total_players"].'</td>
                                    <td>'.round($row["total_players"] / $row["map_count"], 1).'</td>
                                    </tr>';
                                }
                                echo '</tbody>
                                        </table>
                                    </div>
                                </div>';
                            } else {
                                echo '<h3 class="text-center" style="margin-top:15px;">No Statistics Saved Yet.</h3>';
                            }
                            ?>
            </div>
            <?php
$sql = "SELECT * FROM map_stats ORDER BY match_id DESC LIMIT 15";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo '<h1 style="margin-top:15px;">Latest Matches</h1>';
    while ($row = $result->fetch_assoc()) {
        $map_img = array_search($row["map"], $maps);
        $match_id = $row['match_id'];
        if ($row["players_end"] == null) {
            $players_end = "Not Saved";
        } else {
            $players_end = $row["players_end"];
        }
        echo '<div data-bs-hover-animate="pulse" style="margin-top:15px;cursor: pointer;" data-toggle="collapse" data-target="#matchid_'.$match_id.'" aria-expanded="false" aria-controls="matchid_'.$match_id.'">
        <div class="row" style="color:rgb(255,255,255);">
            <div class="col-md-12">
                <div class="card" style="border: none;"><img class="card-img w-100 d-block" sstyle="background-color:#3e3e3f;background-position:center center;background-size: 100% auto;background-image:url(&apos;'.$map_img.'&apos;);height:160px;-webkit-filter:blur(4px);filter:blur(4px);">
                    <div class="card-img-overlay">
                        <div class="row">
                            <div class="col-md-6 text-left">
                                <h4 style="margin-bottom:0px;"><strong>Player Count Start:</strong></h4>
                                <p>'.$row["players_start"].'</p>
                                <h4 style="margin-bottom:0px;"><strong>Player Count End:</strong></h4>
                                <p>'.$players_end.'</p>
                            </div>
                            <div class="col text-right">
                                <h4>'.$row["map"].'</h4>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>';

        echo '<div class="row collapse" id="matchid_'.$match_id.'">
        <div class="col-md-12">
            <div class="table-responsive" style="color:#212529;margin-top:5px;padding-top:5px;">';
            $sql_score = "SELECT * FROM map_stats_players WHERE match_id = '$match_id' ORDER BY kills DESC";
            $result_score = $conn->query($sql_score);
            
            if ($result_score->num_rows > 0) {
                echo '<table class="table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Kills</th>
                        <th>Deaths</th>
                        <th>MVPS</th>
                        <th>KDR</th>
                    </tr>
                </thead>
                <tbody>';
                while ($row = $result_score->fetch_assoc()) {
                    if ($row["kills"] > 0 && $row["deaths"] > 0){
                        $kdr = ($row["kills"] / $row["deaths"]); 
                        $kdr_roundup = round($kdr, 2);
                    } else {
                        $kdr_roundup = $row["kills"];
                    }
                    echo '<tr>
                        <td><a href="https://steamcommunity.com/profiles/'.$row["steamid64"].'">'.$row["name"].'<br></a></td>
                        <td>'.$row["kills"].'</td>
                        <td>'.$row["deaths"].'</td>
                        <td>'.$row["mvps"].'</td>
                        <td>'.$kdr_roundup.'</td>
                    </tr>';
                }
                echo '</tbody>
                </table>';
            } else {
                echo '<h3 class="text-center" style="margin-top:15px;">No Player Satistics Recorded.</h3>';
            }
        echo '</div>
            </div>
           </div>
       </div>';
    }
}

$conn->close();
?>
        </div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.2/js/bootstrap.bundle.min.js"></script>
    <script src="assets/js/script.min.js"></script>
</body>

</html>
