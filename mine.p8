pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

function _init(size,bombs,selected_size,selected_bombs)
    make_game()
    make_intro()
    make_board(size,bombs)
    make_cursor(0,0)
    make_timer()
    make_hud(timer)
    make_menu()
    make_options_menu(selected_size,selected_bombs)
end

function _update()
    if game.state==0 then
        intro:update()
        menu:update()
    elseif game.state==1 then
        cursor:action()
        timer:update()
    elseif game.state==2 or game.state==3 then
        if any_key() then
            _init(board.size,board.total_bombs,options_menu.menu_items[1].selected,options_menu.menu_items[2].selected)
        end
    elseif game.state==4 then
        intro:update()
        options_menu:update()
    elseif game.state==5 then
    end
end

function _draw()
    if game.state==0 then
        intro:draw()
        menu:draw()
    elseif game.state==1 then
        board:draw()
        cursor:draw()
        hud:draw()
    elseif game.state==2 or game.state==3 then
        hud:draw()
        cursor:draw()
    elseif game.state==4 then
        intro:draw()
        options_menu:draw()
    elseif game.state==5 then
    end
end

function make_game()
    --- game_state=0 is intro
    --- game_state=1 game
    --- game_state=2 is gameover loose
    --- game_state=3 is gameover win
    --- game_state=4 is options
    --- game_state=5 is credits
    game={
        state=0,
        start=0,
    }

end

function make_intro()
    cls(13)
    intro={
        draw=function(self)
            spr(2,10,10)
            spr(2,20,10)
            spr(3,20,10)
            spr(5,30,10)
            print(".mine 2020", 40,12,7)
            spr(2,110,100)
            spr(2,100,110)
            spr(2,110,110)
            print("(c) 2020 lucas dima", 10,112,6)
        end,
        update=function(self)
            -- if any_key() then
            --     cls(13)
            --     game_state=1
            -- end
        end
    }
end

function make_menu()
    menu={
        bg_color=13,
        font_color=6,
        bg_color_selected=1,
        font_color_selected=7,
        selected=1,
        vertical_margin=2,
        horizontal_margin=3,
        menu_items={
            'start game',
            'options',
            'credits',
        },
        full_width=0,
        full_height=0,
        draw=function(self)
            local start_x=(128-self.full_width)/2
            local start_y=(128-self.full_height)/2
            local line_height=5+self.vertical_margin*2
            for i,menu_element in pairs(self.menu_items) do
                local font_color=self.font_color
                local bg_color=self.bg_color
                if i==self.selected then
                    font_color=self.font_color_selected
                    bg_color=self.bg_color_selected
                end
                local text_width=(#menu_element*4-2)
                rectfill(start_x,start_y+line_height*(i-1)+1,start_x+self.full_width,start_y+line_height*i,bg_color)
                print(menu_element,(128-text_width)/2,(start_y+line_height*(i-1)+1)+self.vertical_margin,font_color)
            end
        end,
        set_full_width=function(self)
            local max_width=0
            for menu_element in all(self.menu_items) do
                if #menu_element>max_width then
                    max_width=#menu_element
                end
            end
            self.full_width=max_width*4+self.horizontal_margin*2-2
        end,
        set_full_height=function(self)
            self.full_height=#self.menu_items*(5+self.vertical_margin*2)
        end,
        update=function(self)
            if (btnp(2) and self.selected>1) self.selected-=1
            if (btnp(3) and self.selected<#self.menu_items) self.selected+=1
            if (btnp(4) or btnp(5)) then
                cls(13)
                if self.selected==1 then
                    game.state=1
                elseif self.selected==2 then
                    game.state=4
                end
            end
        end,
    }
    menu:set_full_width()
    menu:set_full_height()
end

function make_board_size_menu_item(selected)
    if selected==nil then selected=1 end
    local name='board size:'
    local option_display={' 5x5',' 8x8',' 10x10',' 13x13'}
    local option_values={5,8,10,13}
    local properties={max_bombs={20,60,90,120}}
    local board_size_menu_item=make_option_menu_items(name,option_display,option_values,selected,properties)

    return board_size_menu_item
end

function make_bombs_menu_item(selected)
    if selected==nil then selected=2 end
    local name='bombs:'
    local option_display={' 5',' 10',' 20',' 30',' 50'}
    local option_values={5,10,20,30,50}
    local properties={}

     return make_option_menu_items(name,option_display,option_values,selected,properties)
end

function make_return_menu_item()
    local name='return'
    local option_display={''}
    local option_values={''}
    local selected=1
    local properties={}

    return make_option_menu_items(name,option_display,option_values,selected,properties)
end

function make_option_menu_items(name, option_display,option_values,selected,properties)
    item={
        name=name,
        option_display=option_display,
        option_values=option_values,
        selected=selected,
        display=function(self,i)
            return self.name..self.option_display[i]
        end,
    }
    for key,value in pairs(properties) do
        item[key] = value
    end

    return item
end

function make_options_menu(selected_size,selected_bombs)
    if selected_size==nil then selected_size=1 end
    if selected_bombs==nil then selected_bombs=2 end
    local board_size_menu_item=make_board_size_menu_item(selected_size)
    local bombs_menu_item=make_bombs_menu_item(selected_bombs)
    local return_menu_item=make_return_menu_item()

    options_menu={
        bg_color=13,
        font_color=6,
        bg_color_selected=1,
        font_color_selected=7,
        selected=1,
        vertical_margin=2, -- this is in pixels
        horizontal_margin=3, -- this is in pixels
        menu_items={
            board_size_menu_item,
            bombs_menu_item,
            return_menu_item,
        },
        full_width=0,
        full_height=0,
        draw=function(self)
            local start_x=(128-self.full_width)/2
            local start_y=(128-self.full_height)/2
            local line_height=5+self.vertical_margin*2
            for i,menu_element in pairs(self.menu_items) do
                local font_color=self.font_color
                local bg_color=self.bg_color
                if i==self.selected then
                    font_color=self.font_color_selected
                    bg_color=self.bg_color_selected
                end
                local text=menu_element:display(menu_element.selected)
                local text_width=(#text*4-2)
                rectfill(start_x,start_y+line_height*(i-1)+1,start_x+self.full_width,start_y+line_height*i,bg_color)
                print(text,(128-text_width)/2,(start_y+line_height*(i-1)+1)+self.vertical_margin,font_color)
            end
        end,
        set_full_width=function(self)
            local max_width=0
            for menu_element in all(self.menu_items) do
                for i=1,#menu_element.option_display do
                    -- get max width from all options
                    local text=menu_element:display(i)
                    if #text>max_width then
                        max_width=#text
                    end
                end
            end
            self.full_width=max_width*4+self.horizontal_margin*2-2
        end,
        set_full_height=function(self)
            self.full_height=#self.menu_items*(5+self.vertical_margin*2)
        end,
        update=function(self)
            if btnp(0) then
                local idx=self.menu_items[self.selected].selected-1
                if idx==0 then idx=#self.menu_items[self.selected].option_display end
                self.menu_items[self.selected].selected=idx
            elseif btnp(1) then
                local idx=self.menu_items[self.selected].selected+1
                if idx>#self.menu_items[self.selected].option_display then idx=1 end
                self.menu_items[self.selected].selected=idx
            end
            if (btnp(2) and self.selected>1) self.selected-=1
            if (btnp(3) and self.selected<#self.menu_items) self.selected+=1
            if (btnp(4) or btnp(5)) and self.selected==3 then
                cls(13)
                if self.menu_items[2].option_values[self.menu_items[2].selected] > self.menu_items[1].max_bombs[self.menu_items[1].selected] then
                    self.menu_items[2].option_values[self.menu_items[2].selected] = self.menu_items[1].max_bombs[self.menu_items[1].selected]
                end
                make_board(self.menu_items[1].option_values[self.menu_items[1].selected],self.menu_items[2].option_values[self.menu_items[2].selected])
                game.state=0
            end
        end,
    }
    options_menu:set_full_width()
    options_menu:set_full_height()
end

function make_cursor(x,y)
    cursor = {
        x=x,
        y=y,
        draw=function(self)
            spr(1,self.x * 9 + board.offset_x, self.y * 9 + board.offset_y)
            -- rectfill(0,0,50,10,1)
            -- print(self.x .. "," .. self.y,2,2,5)
        end,
        action=function(self)
            if (btnp(0) and self.x>0) then
                sfx(0)
                self.x-=1
            end
            if (btnp(1) and self.x<board.size-1) self.x+=1
            if (btnp(2) and self.y>0) self.y-=1
            if (btnp(3) and self.y<board.size-1) self.y+=1
            local has_bomb=board:has_bomb(self.x,self.y)
            local total=board:cound_surrounding(self.x, self.y)
            if (btnp(4)) then
                self.handle_open_button(self)
            end
            if (btnp(5)) then
                self.handle_flag_button(self)
            end
        end,
        handle_flag_button=function(self)
            local tile = board:get_tile(self.x,self.y)
            if not tile:is_closed() then return end
            if tile:get_flag() then
                board:decrement_marked_bombs()
                tile:set_flag(false)
            else
                board:increment_marked_bombs()
                tile:set_flag(true)
            end
        end,
        handle_open_button=function(self)
            if game.start==0 then
                board:assign_bombs(self.x,self.y)
                board:assign_nearby()
                game.start=1
            end
            local tile = board:get_tile(self.x,self.y)
            if tile:get_flag() then return end
            tile.closed=false
            if board:has_bomb(self.x,self.y) then
                board:uncover_all()
                game.state=2
                board:draw()
                cursor:draw()
                hud:draw()
                wait(15)
                return
            end
            uncover_recursive(tile,board)
            board:count_uncovered()
            if board:is_all_uncovered() then
                board:uncover_win()
                game.state=3
                board:draw()
                cursor:draw()
                hud:draw()
                wait(30)
                return
            end
        end,
    }
end

function make_board(size,total_bombs)
    if size==nil then size=10 end
    if total_bombs==nil then total_bombs=10 end
    board={
        size=size,
        total_bombs=total_bombs,
        marked_bombs=0,
        uncovered_tiles=0,
        offset_x=0,
        offset_y=0,
        tiles={},
        add_tile=function(self,tile)
            add(self.tiles,tile)
        end,
        draw=function(self)
            for tile in all(self.tiles) do
                tile:draw()
            end
        end,
        set_bomb=function(self,index)
            self.tiles[index]:set_bomb()
        end,
        has_bomb=function(self,x,y)
            tile=self:get_tile(x,y)
            return tile:has_bomb()
        end,
        assign_bombs=function(self,exclude_x,exclude_y)
            -- create array of amount of tiles
            exclude=self:get_index(exclude_x,exclude_y)
            local a={}
            for i=1,#self.tiles do
                if i != exclude then
                    add(a,i)
                end
            end

            -- shuffle the array
            for i=1,1000 do
                rand_pos1 = flr(rnd(count(a)-1)) + 1
                rand_pos2 = flr(rnd(count(a)-1)) + 1
                aux=a[rand_pos1]
                a[rand_pos1]=a[rand_pos2]
                a[rand_pos2]=aux
            end

            -- pick the first (bomb amount elements)
            for i=1,self.total_bombs do
                self:set_bomb(a[i])
            end
        end,
        get_tile=function(self,x,y)
            local index = y*self.size+x+1
            return self.tiles[index]
        end,
        cound_surrounding=function(self,x,y)
            local total=0
            -- top left
            if x>0 and y>0 and self:get_tile(x-1,y-1):has_bomb() then
                total+=1
            end
            -- top
            if y>0 and self:get_tile(x,y-1):has_bomb() then
                 total+=1
            end
            -- top right
            if x<self.size-1 and y>0 and self:get_tile(x+1,y-1):has_bomb() then
                total+=1
            end
            -- right
            if x<self.size-1 and self:get_tile(x+1,y):has_bomb() then
                total+=1
            end
            -- bottom right
            if x<self.size-1 and y<self.size-1 and self:get_tile(x+1,y+1):has_bomb() then
                total+=1
            end
            -- bottom
            if y<self.size-1 and self:get_tile(x,y+1):has_bomb() then
                total+=1
            end
            -- bottom left
            if x>0 and y<self.size-1 and self:get_tile(x-1,y+1):has_bomb() then
                total+=1
            end
            -- left
            if x>0 and self:get_tile(x-1,y):has_bomb() then
                total+=1
            end

            return total
        end,
        get_index=function(self,x,y)
            return (y*self.size+x+1)
        end,
        assign_nearby=function(self)
            for y = 0,self.size-1 do
                for x = 0,self.size-1 do
                    local bombs_near = self:cound_surrounding(x,y)
                    self:get_tile(x,y):set_bombs_near(bombs_near)
                end
            end
        end,
        uncover_all=function(self)
            for tile in all(self.tiles) do
                if tile:has_bomb() then
                    tile:set_closed(false)
                end
            end
        end,
        uncover_win=function(self)
            for tile in all(self.tiles) do
                if tile:has_bomb() then
                    tile:set_flag(true)
                end
            end
        end,
        increment_marked_bombs=function(self)
            self.marked_bombs+=1
        end,
        decrement_marked_bombs=function(self)
            self.marked_bombs-=1
        end,
        count_uncovered=function(self)
            local uncovered=0
            for tile in all(self.tiles) do
                if not tile:is_closed() then
                    uncovered+=1
                end
            end
            self.uncovered_tiles=uncovered
            return uncovered
        end,
        is_all_uncovered=function(self)
            return self.uncovered_tiles + self.total_bombs == self.size * self.size
        end,
    }
    board.offset_x=(128-board.size*9)/2
    board.offset_y=(118-board.size*9)/2+11
    for i = 0,board.size-1 do
        for j = 0,board.size-1 do
            board:add_tile(make_tile(j,i))
        end
    end
    cls(13)
end

function make_tile(x,y)
    local tile = {
        x=x,
        y=y,
        bomb = false,
        closed=true,
        bombs_near=0,
        flag=false,
        draw = function(self)
            if self.closed then
                spr(2,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
                if self.flag then
                    spr(3,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
                end
                return
            end
            if self.bomb then
                spr(5,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
                return
            end
            spr(4,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
            if self.bombs_near>0 then
                -- Add diferent colors to numbers
                local color = self:get_number_color(self.bombs_near)
                print(self.bombs_near,self.x * 9 + board.offset_x + 3,self.y * 9 + board.offset_y + 2,color)
            end
        end,
        get_number_color=function(self, number)
            if number==1 then return 1 end
            if number==2 then return 3 end
            if number==3 then return 8 end
            if number==4 then return 5 end
            if number==5 then return 2 end
            if number==6 then return 12 end
            if number==7 then return 1 end
            if number==8 then return 14 end
        end,
        set_bombs_near=function(self, b)
            self.bombs_near = b
        end,
        set_bomb = function(self)
            self.bomb = true
        end,
        has_bomb = function(self)
            return self.bomb
        end,
        is_closed = function(self)
            return self.closed
        end,
        set_closed=function(self,c)
            self.closed=c
        end,
        set_flag=function(self,f)
            self.flag=f
        end,
        get_flag=function(self)
            return self.flag
        end,
        get_bombs_near=function(self)
            return self.bombs_near
        end
    }
    return tile
end

function make_timer()
    timer={
        seconds=0,
        frames=0,
        update=function(self)
            self.frames+=1
            if self.frames%30==0 then
                self.seconds+=1
                if self.seconds==6000 then
                    self.seconds=0
                end
            end
            if self.frames==30 then
                self.frames=0
            end
        end,
        draw=function(self)
            local min=flr(self.seconds/60)
            local sec=self.seconds%60
            rectfill(100,2,126,8,1)
            print(pad(""..min,2) .. ":" .. pad(""..sec,2),106,2,7)
        end
    }
end

function make_hud(timer)
    hud={
        timer=timer,
        draw=function(self)
            rectfill(0,0,128,8,1)
            print(board.marked_bombs,2,2,7)
            -- rectfill(0,12,128,22,1)
            -- print(board.uncovered_tiles,2,12,5)
            display="mine 2020"
            if game.state==2 then display="game over" end
            if game.state==3 then display="you win!" end
            -- if #self.display>0 then
            print(display,(64-#display*2),2,7)
            -- end
            -- print("mine 2020",(64-9*2),2,7)
            timer:draw()
        end,
    }
end

function debug(m)
    print(m,5,117,5)
end

function any_key()
    return btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5)
end

function uncover_recursive(tile,board)
    tile.closed=false
    if tile:get_bombs_near() > 0 then
        return
    end

    -- check top left
    if tile.x>0 and tile.y>0 then
        top_left_tile=board:get_tile(tile.x-1,tile.y-1)
        if top_left_tile:is_closed() then
            uncover_recursive(top_left_tile,board)
        end
    end

    -- check top
    if tile.y>0 then
        top_tile=board:get_tile(tile.x,tile.y-1)
        if top_tile:is_closed() then
            uncover_recursive(top_tile,board)
        end
    end

    -- check top right
    if tile.x<board.size-1 and tile.y>0 then
        top_right_tile=board:get_tile(tile.x+1,tile.y-1)
        if top_right_tile:is_closed() then
            uncover_recursive(top_right_tile,board)
        end
    end

    -- check right
    if tile.x<board.size-1 then
        right_tile=board:get_tile(tile.x+1,tile.y)
        if right_tile:is_closed() then
            uncover_recursive(right_tile,board)
        end
    end

    -- check bottom right
    if tile.x<board.size-1 and tile.y<board.size-1 then
        bottom_right_tile=board:get_tile(tile.x+1,tile.y+1)
        if bottom_right_tile:is_closed() then
            uncover_recursive(bottom_right_tile,board)
        end
    end

    -- check bottom
    if tile.y<board.size-1 then
        bottom_tile=board:get_tile(tile.x,tile.y+1)
        if bottom_tile:is_closed() then
            uncover_recursive(bottom_tile,board)
        end
    end

    -- check bottom left
    if tile.x>0 and tile.y<board.size-1 then
        bottom_left_tile=board:get_tile(tile.x-1,tile.y+1)
        if bottom_left_tile:is_closed() then
            uncover_recursive(bottom_left_tile,board)
        end
    end
end

function pad(string,length)
  if (#string==length) return string
  local leading_zeros=""
  for i=1,length-#string do
      leading_zeros = leading_zeros.."0"
  end
  return leading_zeros..string
end

function wait(a) for i = 1,a do flip() end end
__gfx__
00000000880000887777777600000000111111161111111600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008000000876666661000000001666666716666a6700000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000007666666100888100166666671666866700000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000000000076666661008a8100166666671661166700000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000007666666100888100166666671617116700000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000007666666100000100166666671611116700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000087666666100000100166666671661166700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000880000886111111100000000677777776777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd77777777dd77777777dd11111117dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666661dd16666a67dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76888161dd16668667dddddd777d777d77dd777ddddd777d777d777d777ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd768a8161dd16611667dddddd777dd7dd7d7d7ddddddddd7d7d7ddd7d7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76888161dd16171167dddddd7d7dd7dd7d7d77dddddd777d7d7d777d7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666161dd16111167dddddd7d7dd7dd7d7d7ddddddd7ddd7d7d7ddd7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666161dd16611667ddd7dd7d7d777d7d7d777ddddd777d777d777d777ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd71111111dd71111111dd77777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddd111d111d111dd11dd11ddddd111d11dd1d1ddddd1d1d111d1d1ddddd111dd11dddddd11d111d111d111d111ddddddddddddddddddddd
dddddddddddddddddddd1d1d1d1d1ddd1ddd1ddddddd1d1d1d1d1d1ddddd1d1d1ddd1d1dddddd1dd1d1ddddd1dddd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddd111d11dd11dd111d111ddddd111d1d1d111ddddd11dd11dd111dddddd1dd1d1ddddd111dd1dd111d11ddd1dddddddddddddddddddddd
dddddddddddddddddddd1ddd1d1d1ddddd1ddd1ddddd1d1d1d1ddd1ddddd1d1d1ddddd1dddddd1dd1d1ddddddd1dd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddd1ddd1d1d111d11dd11dddddd1d1d1d1d111ddddd1d1d111d111dddddd1dd11dddddd11ddd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd71111111dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777dd77777777dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dd76666661dddddddddd
ddddddddddd6ddd66dd6dddddd666d666d666d666ddddd6ddd6d6dd66d666dd66ddddd66dd666d666d666ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddddd6d6d6ddd6d6d6ddddd6ddd6d6d6ddd6d6d6ddddddd6d6dd6dd666d6d6ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddd666d6d6d666d6d6ddddd6ddd6d6d6ddd666d666ddddd6d6dd6dd6d6d666ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddd6ddd6d6d6ddd6d6ddddd6ddd6d6d6ddd6d6ddd6ddddd6d6dd6dd6d6d6d6ddddddddddddddd76666661dd76666661dddddddddd
ddddddddddd6ddd66dd6dddddd666d666d666d666ddddd666dd66dd66d6d6d66dddddd666d666d6d6d6d6ddddddddddddddd76666661dd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd71111111dd71111111dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__sfx__
000500002905026050210500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001f05023050270500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
