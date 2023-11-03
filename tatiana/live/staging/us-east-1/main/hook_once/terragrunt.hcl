
terraform{
  before_hook "before_hook3" {
    commands     = ["apply", "plan","validate"]
    execute = ["echo" ,"I am starting to deploy resources"]
    }
}