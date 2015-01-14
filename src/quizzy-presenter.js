// Presenter
(function () {
  // test data
  quizzes = [{
    id: 1,
    question: "How much wood would a woodchuck chuck?",
    responses: ["3", "42","an inordinate amount","You woodchucks get away from my wood pile!"],
    answer: 1
  }]

  console.log (quizzes)
  
  renderQuizzes()
  
  function renderQuizzes () {
    var question = $("<h3>").text(quizzes.question)
    $(".quiz-question").append(question)
    
    
    //$(".quiz-responses").empty()
    var quizResponses = $(".quiz-responses")
      _.each(quizzes.responses, function(response) {
        var radio = $("<input type='radio'>")
        var span = $("<span>").text(response)
        quizResponses.append(radio)
        quizResponses.append(span)
        quizResponses.append($("<br>"))
        console.log(radio)
      })
  }


}) ()