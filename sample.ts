type ReturnThis = "Past" | "Unknown" | string;

function foo(): ReturnThis {
  return "";
}

const f = foo();
f === "";
