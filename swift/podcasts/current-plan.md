ok, i want to make a view in lib-views called ShowView. it's the view in the podcast app
when the user is looking at a show that they are subscribed to. it will have two parts, a
heading focused on the show, and a list of episodes. but we're only going to work on the
heading part for now

# todos

- [x] create ShowView component in lib-views
- [x] make a lightweight struct in lib-views/Sources/Types to hold the data for the Show
      that the heading will need
- [x] in lib-tca, make an initializer for that struct that takes a Show
- [x] work on the view, making the heading have a light-purple background, and at the top
      a large image of the show, with the title and then the author below it, then the
      description below that
- [x] make previews, light and dark mode
- [x] make a file in lib-tca/Sources/Time.swift that has a function that takes an Int
      (seconds) and returns a String formatted with just minutes and hours, like "1h 5m"
      or "45m", write tests in the style of the other tests
- [x] make the image larger, and i want the purple background to extend behind the notch
      thingy donger
- [x] description a bit further down, and more horizontal padding
- [x] make another func in the Time.swift file that takes a date and returns a String
      indicating how long ago it was, examples: "5D AGO", "3H AGO", "1M AGO", "JUST NOW",
      or "AUG 13" for dates older than a week
- [x] write tests for that func
- [x] in lib-views, make an EpisodeView, and another lightwieght struct to hold the data
      for an episode, and make an initializer in lib-tca for that struct that takes an
      Episode
- [x] make previews for the view, it should display the relative time "6H AGO" (will be
      passed in as string from other module), the title, the description, and the duration
      formatted like "1h 5m" (from other module, passed as string), and an icon to
      indiciate if it's been downloaded or not.
- [x] move the two types in lib-views/Sources/Types.swift into their own files in
      lib-views/Sources/Types/
- [x] make the ShowView take a list of episodes and display them in view below the
      heading, update the previews with several episodes
- [x] reduce the duplication in the previews for the ShowView, use the same episodes for
      all of them, make there be 6 episodes
- [x] the episodes should be the same height, cap description to 3 lines, and make it the
      same height somehow if it has no text
- [x] undo the same height requirement, make all of the previews have a description, still
      cap it to 3 lines
- [x] less space below the heading description, and a tiny bit more padding on the bottom
      of each episode
- [x] even more padding at the bottom of each episode
- [x] i don't like where the duration is displayed, make it float all the way to the right
      of the episode view, above the download icon
- [x] make the "3H AGO" text a lighter by decreasing opacity by 20%, also move it down
      closer to the title a smidge
- [x] download icons smaller
- [x] change the progress field of Episode model in lib-tca to be a Double instead of an
      int, update the migration in the Database.swift file
