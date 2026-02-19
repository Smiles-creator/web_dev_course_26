if ARGV.length != 4
    raise "Неверное кол-во параметров"
 teams_f = ARGV[0];
  unless File.exist?(teams)
   raise "Файла #{teams} нет"
  end
 start_d = ARGV[1];
 end_d = ARGV[2];
 output =  ARGV[3];
 if start_d > end_d
  raise "Дата начала не может быть позже даты конца"
 end
end

  
 def parse_date(str)
    Date.strptime(str, '%d.%m.%y');
 raise "Не удалось пропарсить дату #{str}"   
 end
start_date = parse_date(start_d)
end_date = parse_date(end_d)

teams = [] 
File.foreach(teams_f, encoding: 'UTF-8') do |line|
  line = line.strip
  next if line.empty?
  parts = line.split(/\s*—\s*/)
  if parts.size == 2
    teams << {name: parts[0], city: parts[1]}
  else 
    raise "Неверный формат строки найден в файле #{teams_f}"
  end
end 
  if teams.size < 2
     raise "Нужно хотя бы 2 команды для игры, в файле их меньше"
  end

pairs = teams.combination(2).to_a
pairs.shuffle

slots = []
cur_date = start_d;
while cur_date <= end_date
    if [5, 6, 0].include?(cur_date)
        [12, 15, 18].each do |hour|
            slots << { date: cur_date, time: format('%02d:00', hour) }
        end
    end
    cur_date+=1;
end
if slots.empty?
    raise "В выбранные дни игры не проводятся"
end


schedule = []
slot_index = 0
games_in_slot = 0
pairs.each do |pair|
  current_slot = slots[slot_index]
  
  
  schedule << {
    team1: pair[0][:name],
    team2: pair[1][:name],
    date: current_slot[:date],
    time: current_slot[:time]
  }
  games_in_slot += 1
  
  if games_in_slot >= 2
    slot_index += 1
    games_in_slot = 0
  end
end
