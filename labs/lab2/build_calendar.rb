require 'date'
require 'json'

def parse_date(str)
  begin
    Date.strptime(str, '%d.%m.%Y')
  rescue ArgumentError
    raise "Некорректный формат даты '#{str}'. Ожидаемый формат: ДД.ММ.ГГГГ"
  end
end

begin
  if ARGV.length != 4
    raise "Ошибка: Неверное количество аргументов.\n" +
          "Использование: ruby build_calendar.rb teams.txt <дата_начала> <дата_конца> <файл_вывода>\n"
  end
  teams_file = ARGV[0]
  start_str = ARGV[1]
  end_str = ARGV[2]
  output_file = ARGV[3]

  unless File.exist?(teams_file)
    raise "Ошибка: Файл команд '#{teams_file}' не найден."
  end


  start_date = parse_date(start_str)
  end_date = parse_date(end_str)
  if start_date > end_date
    raise "Ошибка: Дата начала (#{start_str}) не может быть позже даты конца (#{end_str})."
  end

  teams = []
  line_number = 0
  File.foreach(teams_file, encoding: 'UTF-8') do |line|
    line_number += 1
    line = line.strip
    next if line.empty? || line.start_with?('#')
    parts = line.split(/\s*—\s*/)
    if parts.size != 2
      raise "Ошибка в файле #{teams_file} (строка #{line_number}): Неверный формат #{line}.\n"
    end
    teams << { name: parts[0], city: parts[1]}
  end
  if teams.size < 2
    raise "Ошибка: Для проведения игры нужно минимум 2 команды."
  end

 # puts "Загружено команд: #{teams.size}"
  pairs = teams.combination(2).to_a
  pairs.shuffle!

  
  slots = []
  current_date = start_date
  while current_date <= end_date
    if [5, 6, 0].include?(current_date.wday)
      [12, 15, 18].each do |hour|
        slots << { date: current_date, time: format('%2d:00', hour) }
      end
    end
    current_date += 1
  end
  if slots.empty?
    raise "Ошибка: В выбранном диапазоне дат не проводятся игры"
  end

  
  total_games = pairs.size
  total_slots = slots.size
  slots.each { |s| s[:current_load] = 0 } #что-то по типу счетчика у каждого слота
  schedule = []
  pairs.each do |pair|
    # расчетный индекс для равномерности
    start_index = (schedule.size * total_slots) / total_games
    slot_idx = start_index
    found = false
    total_slots.times do
      if slots[slot_idx][:current_load] < 2
        found = true
        break
      end
      slot_idx = (slot_idx + 1) % total_slots
    end
    unless found
      raise "Ошибка: Не хватило слотов для равномерного распределения. Увеличьте диапазон дат."
    end
    current_slot = slots[slot_idx]
    schedule << {
      team1: pair[0][:name],
      team1_city: pair[0][:city], 
      team2: pair[1][:name],
      team2_city: pair[1][:city],
      date: current_slot[:date],
      time: current_slot[:time]
    }
    current_slot[:current_load] += 1
  end


  output_data = {
    meta: {
      title: "Спортивный календарь",
      period: "#{start_date.strftime('%d.%m.%Y')} - #{end_date.strftime('%d.%m.%Y')}",
      teams_count: teams.size,
      total_games: schedule.size
    },
    games: schedule.map do |game|
      {
        date: game[:date].strftime('%d-%m-%Y'),
        time: game[:time],
        day_of_week: %w[Вс Пн Вт Ср Чт Пт Сб][game[:date].wday],
        home_team: game[:team1],
        home_city: game[:team1_city],
        away_team: game[:team2],
        away_city: game[:team2_city] 

      }
    end
  }


  File.open(output_file, 'w', encoding: 'UTF-8') do |f|
    f.write(JSON.pretty_generate(output_data))
  end


rescue => e
  # ловит рейс, иначе вылазят страшные ошибки
  puts "\nОШИБКА: #{e.message}"
  exit
end